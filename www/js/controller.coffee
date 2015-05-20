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
				name: $scope.model.fullname()
			item.$save()

# vcard detail view
VCardDetailCtrl = ($scope, $stateParams, resource) ->
	collection = resource.VCards.instance()
	$scope.model = _.findWhere collection.models, jid: $stateParams.jid 
	
# vcard update view
VCardUpdateCtrl = ($scope, $state, model) ->
	_.extend $scope,
		model: model
		save: ->
			model.$save().then ->
				$state.go 'app.vcard.list'
	
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
	
ChatCtrl = ($scope, $ionicModal) ->
	return

ImgCropCtrl = ($scope, $attrs, pageableAR, resource) ->
	_.extend $scope,
		model: new pageableAR.Model src: $scope.$eval($attrs.model)
		select: (files) ->
			if files.length != 0
				reader = new FileReader()
				reader.onload = (event) =>
					@model.src = event.target.result
					$scope.$apply 'model.src'
				reader.readAsDataURL(files[0])

VCardsFilter = ->
	(vcards, search) ->
		return _.filter vcards, (vcard) ->
			vcard.fullname().indexOf(search) > -1 or vcard.post().indexOf(search) > -1
	
RosterFilter = ->
	(roster, search) ->
		return _.filter roster, (item) ->
			item.name.indexOf(search) > -1 or item.jid.indexOf(search) > -1
					
angular.module('starter.controller', ['ionic', 'ngCordova', 'http-auth-interceptor', 'starter.model', 'platform', 'PageableAR'])
	.filter 'vcardsFilter', VCardsFilter
	.filter 'rosterFilter', RosterFilter
	.controller 'AppCtrl', ['$rootScope', '$scope', '$http', '$sailsSocket', 'platform', 'authService', AppCtrl]
	.controller 'MenuCtrl', ['$scope', MenuCtrl]
	.controller 'RosterItemCtrl', ['$rootScope', '$scope', '$ionicModal', RosterItemCtrl]
	.controller 'RosterCtrl', ['$scope', 'collection', RosterCtrl]
	.controller 'VCardCtrl', ['$scope', 'pageableAR', 'resource', VCardCtrl]
	.controller 'VCardDetailCtrl', ['$scope', '$stateParams', 'resource', VCardDetailCtrl]
	.controller 'VCardUpdateCtrl', ['$scope', '$state', 'model', VCardUpdateCtrl]
	.controller 'VCardsCtrl', ['$scope', 'pageableAR', 'collection', VCardsCtrl]
	.controller 'ImgCropCtrl', ['$scope', '$attrs', 'pageableAR', 'resource', ImgCropCtrl]