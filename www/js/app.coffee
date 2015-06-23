angular.module('starter', ['ionic', 'starter.controller', 'starter.model', 'http-auth-interceptor', 'ngTagEditor', 'ActiveRecord', 'ngFileUpload', 'ngTouch', 'ngImgCrop', 'ngFancySelect'])
	
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
					resource.Users.instance()
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
					resource.User.me()
			onEnter: (model) ->
				model.$fetch()
		
		$stateProvider.state 'app.vcard.read',
			url: "/:jid"
			views:
				vcardContent:
					templateUrl: 'templates/vcard/read.html'
					controller: 'VCardDetailCtrl'
					
		$stateProvider.state 'app.vcard.photo',
			url: '/photo'
			views:
				vcardContent:
					templateUrl: 'templates/vcard/photo.html'
					controller: 'VCardPhotoCtrl'
			resolve:
				resource: 'resource'
				model: (resource) ->
					resource.User.me()
					
		$stateProvider.state 'app.chat',
			url: "/chat"
			abstract: true
			views:
				menuContent:
					templateUrl: "templates/chat/index.html"
					
		$stateProvider.state 'app.chat.list',
			url: "/:jid"
			views:
				chatContent:
					templateUrl: 'templates/chat/list.html'
					controller: 'ChatCtrl'
			resolve:
				resource: 'resource'
				jid: ($stateParams) ->
					$stateParams.jid
				chat: (resource, jid) ->
					_.find resource.Roster.instance().models, (item) ->
						item.user.jid == jid
				me: (resource) ->
					resource.User.me()
				collection: (resource) ->
					new resource.Msgs()
			onEnter: (jid, me, collection) ->
				me.$fetch()
				collection?.$fetch reset: true, params: {to: jid, sort: 'createdAt DESC'}
				
		$urlRouterProvider.otherwise('/roster')
	
	.run ($ionicPlatform, $location, $http, $sailsSocket, OAuthService, resource) ->
		$ionicPlatform.ready ->
			if (window.cordova && window.cordova.plugins.Keyboard)
				cordova.plugins.Keyboard.hideKeyboardAccessoryBar(true)
			if (window.StatusBar)
				StatusBar.styleDefault()
				
		# listen if access granted or denied in child window
		$.receiveMessage (event) ->
			data = $.deparam event.data
			if data.error
				OAuthService.loginCancelled null, data.error
			else
				OAuthService.loginConfirmed data
					
		# notify parent window if access_token is available or access denied
		url = $location.absUrl()
		resolve = (data) ->
			$.postMessage data, url
		reject = (err) ->
			$.postMessage err, url
		OAuthService.matchUrl $location.absUrl(), resolve, reject
		
		# update status of current login user once connected
		io.socket.on 'connect', (event) ->
			resource.User.me().$save
				online:	true
				status:	'available'
				
		# subscribe to users update
		resource.Users.instance().$fetch()