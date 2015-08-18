env = require './env.coffee'

angular.module('starter', ['ionic', 'starter.controller', 'starter.model', 'http-auth-interceptor', 'ngTagEditor', 'ActiveRecord', 'ngFileUpload', 'ngTouch', 'ngImgCrop', 'ngFancySelect', 'ngIcon'])
	
	.config ($stateProvider, $urlRouterProvider, $ionicConfigProvider) ->
		$stateProvider.state 'app',
			url: ""
			abstract: true
			templateUrl: "templates/menu.html"
	
		$urlRouterProvider.otherwise('/roster/list')
		
		$ionicConfigProvider.tabs.style 'standard'
		$ionicConfigProvider.tabs.position 'bottom'
	
	.run ($ionicPlatform, $cordovaDevice, $cordovaLocalNotification, $location, $http, $sailsSocket, $rootScope, $ionicModal, platform, OAuthService, AlertService, resource) ->
		window.alert = AlertService.alert
		
		$ionicPlatform.ready ->
			if env.isNative()
				cordova.plugins.Keyboard?.hideKeyboardAccessoryBar(true)
				StatusBar?.styleDefault()
				platform.pushRegister()
				
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
				status:	resource.User.type.status[0]
				
		# subscribe to users update
		resource.Users.instance().$fetch()
		
		$rootScope.$on '$stateChangeError', (evt, toState, toParams, fromState, fromParams, error) ->
			window.alert error.data
	
		auth = _.once platform.auth
		$rootScope.$on 'event:auth-forbidden', ->
			auth()
		$rootScope.$on 'event:auth-loginRequired', ->
			auth()
		$rootScope.$on 'event:auth-loginConfirmed', ->
			# auth is successfully called once, new auth process for token expiry
			auth = _.once platform.auth
			$rootScope.modal?.remove()
		$rootScope.$on 'event:auth-loginCancelled', ->
			# auth is successfully called once, new auth process for token expiry
			auth = _.once platform.auth
			$rootScope.modal?.remove()
		
		$rootScope.$on 'cropImg', (event, inImg) ->
			_.extend $rootScope,
				model: 
					inImg: inImg
					outImg: ''
				confirm: ->
					$rootScope.$broadcast 'cropImg.completed', $rootScope.model.outImg
					$rootScope.modal?.remove()
			$ionicModal.fromTemplateUrl 'templates/img/crop.html', scope: $rootScope
				.then (modal) ->
					modal.show()
					$rootScope.modal = modal
					
		$rootScope.$on '$cordovaPush:notificationReceived', (event, notification) ->
			switch notification.event
				when 'registered'
					device = new resource.Device
						regid: 		notification.regid
						model:		$cordovaDevice.getModel()
						version:	$cordovaDevice.getVersion()
					device.$save().catch alert
				when 'message'
					$location.path notification.payload.url
					$cordovaLocalNotification.add
						title:	notification.payload.msg
				else
					alert notification