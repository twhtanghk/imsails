env = require './env.coffee'

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

AppCtrl = ($rootScope, platform, OAuthService) ->
	$rootScope.$on 'event:auth-forbidden', ->
		platform.auth()
	$rootScope.$on 'event:auth-loginRequired', ->
		platform.auth()
	$rootScope.$on 'event:auth-loginConfirmed', ->
		$rootScope.modal?.remove()
	$rootScope.$on 'event:auth-loginCancelled', (data) ->
		$rootScope.modal?.remove()
		
MenuCtrl = ($scope) ->
	$scope.env = env
	$scope.navigator = navigator
				
RosterItemCtrl = ($rootScope, $scope, $ionicModal) ->
	_.extend $scope,
		edit: ->
			return
		remove: ->
			$scope.collection.remove $scope.model

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
				jid: $scope.model.jid
				name: $scope.model.fullname
			item.$save()

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
	
ChatCtrl = ($scope, $ionicScrollDelegate, jid, collection, resource) ->
	item = _.findWhere resource.Roster.instance().models, jid: jid
	
	_.extend $scope,
		chat: item
		collection: collection
		loadMore: ->
			collection.$fetch params: to: jid
				.then ->
					$scope.$broadcast('scroll.infiniteScrollComplete')
				.catch alert
			return @
		send: ->
			msg = new resource.Msg to: jid, body: $scope.msg
			msg.$save()
				.then ->
					collection.add msg
					$scope.msg = ''
				.catch alert
	
	$scope.$watchCollection 'collection.models', (newmodels, oldmodels) ->
		if newmodels.length != oldmodels.length
			$ionicScrollDelegate.scrollBottom true		

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
		return _.filter vcards, (vcard) ->
			vcard.fullname.indexOf(search) > -1 or vcard.post.indexOf(search) > -1
	
RosterFilter = ->
	(roster, search) ->
		return _.filter roster, (item) ->
			item.name.indexOf(search) > -1 or item.jid.indexOf(search) > -1
	
MsgFilter = ->
	(msgs, search) ->
		return _.filter msgs, (msg) ->
			msg.body.indexOf(search) > -1
							
angular.module('starter.controller', ['ionic', 'ngCordova', 'http-auth-interceptor', 'starter.model', 'platform', 'PageableAR'])
	.factory 'OAuthService', ['$http', '$sailsSocket', 'authService', OAuthService]
	.filter 'vcardsFilter', VCardsFilter
	.filter 'rosterFilter', RosterFilter
	.filter 'msgFilter', MsgFilter
	.controller 'AppCtrl', ['$rootScope', 'platform', 'OAuthService', AppCtrl]
	.controller 'MenuCtrl', ['$scope', MenuCtrl]
	.controller 'RosterItemCtrl', ['$rootScope', '$scope', '$ionicModal', RosterItemCtrl]
	.controller 'RosterCtrl', ['$scope', 'collection', RosterCtrl]
	.controller 'VCardCtrl', ['$scope', 'pageableAR', 'resource', VCardCtrl]
	.controller 'VCardDetailCtrl', ['$scope', '$stateParams', 'resource', VCardDetailCtrl]
	.controller 'VCardUpdateCtrl', ['$scope', '$state', 'model', VCardUpdateCtrl]
	.controller 'VCardPhotoCtrl', ['$scope', '$state', 'model', VCardPhotoCtrl]
	.controller 'VCardsCtrl', ['$scope', 'pageableAR', 'collection', VCardsCtrl]
	.controller 'ChatCtrl', ['$scope', '$ionicScrollDelegate', 'jid', 'collection', 'resource', ChatCtrl]
	.controller 'SelectCtrl', ['$scope', SelectCtrl]