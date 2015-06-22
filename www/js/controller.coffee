env = require './env.coffee'
_ = require 'lodash'
urlparser = require 'url'

OAuthService = ($http, $sailsSocket, authService) ->
	# set authorization header once oauth2 token is available
	loginConfirmed: (data, configUpdater) ->
		if data?
			$http.defaults.headers.common.Authorization = "Bearer #{data.access_token}"
			$sailsSocket.defaults.headers.common.Authorization = "Bearer #{data.access_token}"
			authService.loginConfirmed()
		
	loginCancelled:	(data, reason) ->
		console.error reason
		authService.loginCancelled(data, reason)

	# check if input url match error or acess_token
	# then trigger fulfill(data) or reject(err) 
	matchUrl: (url, resolve, reject) ->
		if url.match(/error|access_token/)
			path = urlparser.parse(url)
			data = $.deparam /(?:[#\/]*)(.*)/.exec(path.hash)[1]	# remove leading / or #
			err = $.deparam /\?*(.*)/.exec(path.search)[1]			# remove leading ?
			if err.error
				reject err 
			else
				resolve data
			
AppCtrl = ($rootScope, platform, OAuthService) ->
	auth = _.once platform.auth
	$rootScope.$on 'event:auth-forbidden', ->
		auth()
	$rootScope.$on 'event:auth-loginRequired', ->
		auth()
	$rootScope.$on 'event:auth-loginConfirmed', ->
		# auth is successfully called once, new auth process for token expiry
		auth = _.once platform.auth
		$rootScope.modal?.remove()
	$rootScope.$on 'event:auth-loginCancelled', (data) ->
		$rootScope.modal?.remove()
		
MenuCtrl = ($scope) ->
	_.extend $scope,
		env: env
		exit: ->
			io.socket.disconnect()
			navigator.app.exitApp()
				
RosterItemCtrl = ($rootScope, $scope, $ionicModal, resource) ->
	_.extend $scope,
		edit: ->
			return
		remove: ->
			$scope.collection.remove $scope.model
			
	# listen if user status is updated
	io.socket.on "user", (event) ->
		if event.verb == 'updated' and event.id == $scope.model.user.id
			_.extend $scope.model.user, event.data
			$scope.$apply 'model'
					
RosterCtrl = ($scope, collection) ->
	_.extend $scope,
		searchText:		''
		collection:		collection
		loadMore: ->
			collection.$fetch()
				.then ->
					$scope.$broadcast('scroll.infiniteScrollComplete')
				.catch alert
			return @

# vcard list item view
VCardCtrl = ($scope, pageableAR, resource) ->
	_.extend $scope,
		addRoster: ->
			item = new resource.RosterItem
				user: $scope.model
			item.$save()

	# listen if user status is updated
	io.socket.on "user", (event) ->
		if event.verb == 'updated' and event.id == $scope.model.id
			_.extend $scope.model, event.data
			$scope.$apply 'model'
			
# vcard detail view
VCardDetailCtrl = ($scope, $stateParams, resource) ->
	collection = resource.Users.instance()
	$scope.model = _.findWhere collection.models, jid: $stateParams.jid 
	
# vcard update view
VCardUpdateCtrl = ($scope, $state, model) ->
	_.extend $scope,
		model: model
		buffer:
			phone:
				placeholder: 	'Phone'
				typeAvail:		['Mobile', 'Office', 'Home', 'Other']
				type:			'Mobile'
				value:			''
			otherEmail:
				title:			'Email'
				placeholder:	'Email'
				typeAvail:		['Office', 'Home', 'Other']
				type:			'Office'
				value:			''
			address:
				placeholder:	'Address'
				typeAvail:		['Office', 'Home', 'Other']
				type:			'Office'
				value:			''
		save: ->
			model.$save().then ->
				$state.go 'app.vcard.list'
		select: (files) ->
			if files.length != 0
				reader = new FileReader()
				reader.onload = (event) =>
					@model.photoUrl = event.target.result
					$state.go 'app.vcard.photo'
				reader.readAsDataURL(files[0])

# vcard photo update view
VCardPhotoCtrl = ($scope, $state, model) ->
	_.extend $scope,
		model: model
		src: model.photoUrl
		save: ->
			model.$save().then ->
				$state.go 'app.vcard.update'
				
VCardsCtrl = ($scope, pageableAR, collection) ->
	_.extend $scope,
		searchText:		''
		collection:		collection
		loadMore: ->
			collection.$fetch()
				.then ->
					$scope.$broadcast('scroll.infiniteScrollComplete')
				.catch alert
			return @
	
ChatCtrl = ($scope, $ionicScrollDelegate, jid, chat, me, collection, resource) ->
	_.extend $scope,
		chat: chat
		me: me
		collection: collection
		loadMore: ->
			collection.$fetch params: {to: jid, sort: 'createdAt DESC'}
				.then ->
					$scope.$broadcast('scroll.infiniteScrollComplete')
				.catch alert
			return @
		send: ->
			msg = new resource.Msg to: jid, body: $scope.msg
			msg.$save()
				.then ->
					collection.add msg
					$ionicScrollDelegate.scrollTop true
					$scope.msg = ''
				.catch alert
	
	# listen if msg is created on server
	io.socket.on "msg", (event) ->
		if event.verb == 'created'
			collection.add new resource.Msg event.data
			$scope.$apply('collection.models')
			$ionicScrollDelegate.scrollTop true
	
###
create model from $scope input parameter for fancySelect model
in:
	options: 	[opt1, opt2, ...]
	item.type:	value
out:
	model: [{text: opt1, selected: true|false}, ...]
###
SelectCtrl = ($scope) ->
	$scope.model = 
		_.map $scope.options, (opt) ->
			text: opt
			selected: opt == $scope.item.type
				
	$scope.$on 'selected', (event, values) ->
		$scope.item.type = values[0] || '' 
		
VCardsFilter = ->
	(vcards, search) ->
		if search
			return _.filter vcards, (vcard) ->
				vcard.fullname.indexOf(search) > -1 or vcard.post.indexOf(search) > -1
		else
			return vcards
	
RosterFilter = ->
	(roster, search) ->
		if search
			return _.filter roster, (item) ->
				item.name.indexOf(search) > -1 or item.jid.indexOf(search) > -1
		else
			return roster
	
MsgFilter = ->
	(msgs, search) ->
		if search
			return _.filter msgs, (msg) ->
				msg.body.indexOf(search) > -1
		else
			return msgs
							
angular.module('starter.controller', ['ionic', 'ngCordova', 'http-auth-interceptor', 'starter.model', 'platform', 'PageableAR'])
	.factory 'OAuthService', ['$http', '$sailsSocket', 'authService', OAuthService]
	.filter 'vcardsFilter', VCardsFilter
	.filter 'rosterFilter', RosterFilter
	.filter 'msgFilter', MsgFilter
	.controller 'AppCtrl', ['$rootScope', 'platform', 'OAuthService', AppCtrl]
	.controller 'MenuCtrl', ['$scope', MenuCtrl]
	.controller 'RosterItemCtrl', ['$rootScope', '$scope', '$ionicModal', 'resource', RosterItemCtrl]
	.controller 'RosterCtrl', ['$scope', 'collection', RosterCtrl]
	.controller 'VCardCtrl', ['$scope', 'pageableAR', 'resource', VCardCtrl]
	.controller 'VCardDetailCtrl', ['$scope', '$stateParams', 'resource', VCardDetailCtrl]
	.controller 'VCardUpdateCtrl', ['$scope', '$state', 'model', VCardUpdateCtrl]
	.controller 'VCardPhotoCtrl', ['$scope', '$state', 'model', VCardPhotoCtrl]
	.controller 'VCardsCtrl', ['$scope', 'pageableAR', 'collection', VCardsCtrl]
	.controller 'ChatCtrl', ['$scope', '$ionicScrollDelegate', 'jid', 'chat', 'me', 'collection', 'resource', ChatCtrl]
	.controller 'SelectCtrl', ['$scope', SelectCtrl]