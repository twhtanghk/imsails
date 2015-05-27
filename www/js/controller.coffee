env = require './env.coffee'

AppCtrl = ($rootScope, $scope, $http, $sailsSocket, platform, authService) ->	
	# set authorization header once mobile authentication completed
	fulfill = (data) ->
		if data?
			$http.defaults.headers.common.Authorization = "Bearer #{data.access_token}"
			$sailsSocket.defaults.headers.common.Authorization = "Bearer #{data.access_token}"
			authService.loginConfirmed()
	
	$scope.$on 'event:auth-forbidden', ->
		platform.auth().then fulfill, alert
	$scope.$on 'event:auth-loginRequired', ->
		platform.auth().then fulfill, alert
	
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
				placeholder: 	'Number'
				typeAvail:		['Mobile', 'Office', 'Home', 'Other']
				type:			'Mobile'
				value:			''
			otherEmail:
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
					$scope.$apply 'model.photoUrl'
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
	.filter 'vcardsFilter', VCardsFilter
	.filter 'rosterFilter', RosterFilter
	.filter 'msgFilter', MsgFilter
	.controller 'AppCtrl', ['$rootScope', '$scope', '$http', '$sailsSocket', 'platform', 'authService', AppCtrl]
	.controller 'MenuCtrl', ['$scope', MenuCtrl]
	.controller 'RosterItemCtrl', ['$rootScope', '$scope', '$ionicModal', RosterItemCtrl]
	.controller 'RosterCtrl', ['$scope', 'collection', RosterCtrl]
	.controller 'VCardCtrl', ['$scope', 'pageableAR', 'resource', VCardCtrl]
	.controller 'VCardDetailCtrl', ['$scope', '$stateParams', 'resource', VCardDetailCtrl]
	.controller 'VCardUpdateCtrl', ['$scope', '$state', 'model', VCardUpdateCtrl]
	.controller 'VCardPhotoCtrl', ['$scope', '$state', 'model', VCardPhotoCtrl]
	.controller 'VCardsCtrl', ['$scope', 'pageableAR', 'collection', VCardsCtrl]
	.controller 'ChatCtrl', ['$scope', '$ionicScrollDelegate', 'jid', 'collection', 'resource', ChatCtrl]