env = require '../env.coffee'
mime = require 'mime-types/index.js'

domain =
	state: ($stateProvider) ->
		$stateProvider.state 'app.chat',
			url: "/chat"
			abstract: true
			views:
				menuContent:
					templateUrl: "templates/chat/index.html"
					
		$stateProvider.state 'app.chat.list',
			cache: false
			url: "/:type/:id"
			views:
				chatContent:
					templateUrl: 'templates/chat/list.html'
					controller: 'ChatCtrl'
			resolve:
				resource: 'resource'
				type: ($stateParams) ->
					$stateParams.type
				id: ($stateParams) ->
					$stateParams.id
				chat: (resource, type, id) ->
					ret = if type == 'chat' then new resource.User id: id else new resource.Group id: id
					ret.$fetch() 
				me: (resource) ->
					resource.User.me()
				collection: (type, chat, resource) ->
					ret = new resource.Msgs()
					ret.$fetch params: {type: type, to: chat.jid, sort: 'createdAt DESC'}
			onExit: (resource, chat) ->
				# clear roster newmsg counter
				item = _.findWhere resource.Roster.instance().models, jid: chat.jid
				item?.$save(newmsg: 0)			
				
				# no more listen to those registered events
				io.socket?.removeAllListeners 'msg'
			
	list: ($scope, $cordovaClipboard, $cordovaToast, $ionicScrollDelegate, $location, type, chat, me, collection, resource, platform) ->
		_.extend $scope,
			type: type
			chat: chat
			me: me
			collection: collection
			msg: ''
			loadMore: ->
				collection.$fetch params: {type: type, to: chat.jid, sort: 'createdAt DESC'}
					.then ->
						$scope.$broadcast('scroll.infiniteScrollComplete')
					.catch alert
				return @
			send: ->
				if $scope.msg != ''
					msg = new resource.Msg type: type, to: chat.jid, body: $scope.msg
					msg.$save().catch alert
					$scope.msg = ''
			putfile: ($files) ->
				if $files.length != 0
					attachment = new resource.Attachment type: type, to: chat.jid, file: $files[0]
					attachment.$save().catch alert
			getfile: (msg) ->
				attachment = new resource.Attachment id: msg.id
				target = env.file.target(msg.file.base)
				attachment.$fetch(target: target)
					.then (res) =>
						platform
							.open(target, mime.lookup(target))
							.catch alert
					.catch alert
			copy: (msg) ->
				if env.isNative()
					$cordovaClipboard.copy(msg.body)
						.then ->
							$cordovaToast.showShortCenter("Message copied")
						.catch alert
		
		# reload collection once reconnected
		io.socket?.on 'connect', (event) ->
			if $location.url().indexOf('/chat') != -1
				$scope.collection.$fetch  params: {type: type, to: chat.jid, sort: 'createdAt DESC'}, reset: true 
		
		# listen if msg is created on server
		isValid = (msg) ->
			if type == 'chat'
				return (msg.from == chat.jid and msg.to == me.jid) or (msg.to == chat.jid and msg.from == me.jid)
			else
				return msg.to == chat.jid
		io.socket?.on "msg", (event) ->
			if event.verb == 'created'
				if isValid(event.data) 
					collection.add new resource.Msg event.data
					$scope.$apply('collection.models')
					$ionicScrollDelegate.scrollTop true

filter =
	list: ->
		(msgs, search) ->
			if search
				return _.filter msgs, (msg) ->
					msg.body.indexOf(search) > -1
			else
				return msgs
		
module.exports = (angularModule) ->
	angularModule
		.config ['$stateProvider', domain.state]
		.controller 'ChatCtrl', ['$scope', '$cordovaClipboard', '$cordovaToast', '$ionicScrollDelegate', '$location', 'type', 'chat', 'me', 'collection', 'resource', 'platform', domain.list]
		.filter 'msgFilter', filter.list