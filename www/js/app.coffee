angular.module('starter', ['ionic', 'starter.controller', 'starter.model', 'http-auth-interceptor', 'ngTagEditor', 'ActiveRecord', 'ngFileUpload', 'ngTouch', 'ngImgCrop'])
	
	.config ($stateProvider, $urlRouterProvider) ->
		$stateProvider.state 'app',
			url: ""
			abstract: true
			controller: 'AppCtrl'
			templateUrl: "templates/menu.html"
			
		$stateProvider.state 'app.roster',
			url: "/roster"
			views:
				menuContent:
					templateUrl: 'templates/roster/list.html'
					controller: 'RosterCtrl'
			resolve:
				resource: 'resource'
				collection: (resource) ->
					resource.Roster.instance()
			onEnter: (collection) ->
				collection?.$fetch reset: true
			
		$stateProvider.state 'app.vcard',
			url: "/vcard"
			abstract: true
			views:
				menuContent:
					templateUrl: "templates/vcard/index.html"
			
		$stateProvider.state 'app.vcard.list',
			url: "/list"
			views:
				vcardContent:
					templateUrl: 'templates/vcard/list.html'
					controller: 'VCardsCtrl'
			resolve:
				resource: 'resource'
				collection: (resource) ->
					resource.VCards.instance()
			onEnter: (collection) ->
				collection?.$fetch reset: true
				
		$stateProvider.state 'app.vcard.update',
			url: '/update'
			views:
				vcardContent:
					templateUrl: 'templates/vcard/update.html'
					controller: 'VCardUpdateCtrl'
			resolve:
				resource: 'resource'
				model: (resource) ->
					new resource.VCard jid: 'me'
			onEnter: (model) ->
				model.$fetch()
		
		$stateProvider.state 'app.vcard.read',
			url: "/:jid"
			views:
				vcardContent:
					templateUrl: 'templates/vcard/read.html'
					controller: 'VCardDetailCtrl'
					
		$stateProvider.state 'app.chat',
			url: "chat"
			views:
				'menuContent':
					templateUrl: "templates/chat/list.html"
					controller: 'ChatCtrl'
					
		$urlRouterProvider.otherwise('/roster')
	
	.run ($ionicPlatform, $location, $http, authService) ->
		$ionicPlatform.ready ->
			if (window.cordova && window.cordova.plugins.Keyboard)
				cordova.plugins.Keyboard.hideKeyboardAccessoryBar(true)
			if (window.StatusBar)
				StatusBar.styleDefault()
			
		# set authorization header once browser authentication completed
		if $location.url().match /access_token/
				data = $.deparam $location.url().split("/")[1]
				$http.defaults.headers.common.Authorization = "Bearer #{data.access_token}"
				authService.loginConfirmed()