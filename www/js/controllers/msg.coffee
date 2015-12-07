env = require '../env.coffee'
					
module.exports = (angularModule) ->

	angularModule

		.config ($stateProvider) ->
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
						
				onEnter: (resource, chat) ->
					# clear roster newmsg counter
					item = _.findWhere resource.Roster.instance().models, jid: chat.jid
					item?.$save(newmsg: 0)			
					 
				onExit: ->
					# no more listen to those registered events
					io.socket?.removeAllListeners 'msg'
			
		.controller 'ChatCtrl', ($scope, $cordovaMedia, $cordovaClipboard, toaster, $ionicScrollDelegate, $location, type, chat, me, collection, resource, platform, $cordovaCapture, fileService, audioService) ->
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
				# to control no of rows required for the input textarea
				row: (msg) ->
					rows = if msg == '' then 1 else Math.min(3, msg.split('\n').length)
					$('textarea').attr('rows', rows).css('overflow-y', if rows == 1 then 'hidden' else 'scroll') 
					return false
				send: ->
					if $scope.msg != ''
						msg = new resource.Msg type: type, to: chat.jid, body: $scope.msg
						msg.$save().catch alert
						$scope.msg = ''
						$scope.row('')
				putfile: ($files) ->
					if $files and $files.length != 0
						attachment = new resource.Attachment type: type, to: chat.jid, local: $files[0]
						attachment.$save().catch alert
				record: 
					start: ->
						audioService.recorder.start()
					stop: ->
						audioService.recorder.stop()
						audioService.recorder.file env.file.audio
							.then (file) ->
								$scope.putfile [file]
				copy: (msg) ->
					if env.isNative()
						$cordovaClipboard.copy(msg.body)
							.then ->
								toaster.pop
									type:	'info'
									body:	'Message copied'
									bodyOutputType: 'trustedHtml'
							.catch alert
			
			# reload collection once reconnected
			io.socket?.on 'connect', (event) ->
				if $location.url().indexOf('/chat') != -1
					$scope.collection.$refetch params: {type: type, to: chat.jid, sort: 'createdAt DESC'}
			
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
			
		.controller 'msgCtrl', ($scope, $http, audioService, resource, fileService) ->
			token =	$http.defaults.headers.common.Authorization.split(' ')[1]
			_.extend $scope, 
				getfile: ->
					$scope.model.attachment.$saveAs()
						
		.filter 'msgFilter', ->
			(msgs, search) ->
				if search
					return _.filter msgs, (msg) ->
						r = new RegExp(search, 'i')
						r.test(msg.body) or r.test(msg.file?.base)
				else
					return msgs