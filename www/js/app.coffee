env = require './env.coffee'

angular.module('starter', ['ionic', 'starter.controller', 'starter.model', 'locale', 'auth', 'ngTagEditor', 'ActiveRecord', 'ngFileUpload', 'ngTouch', 'ngImgCrop', 'ngFancySelect', 'ngIcon', 'templates'])
	
	.config ($urlRouterProvider, $ionicConfigProvider, $provide) ->
		$urlRouterProvider.otherwise('/roster/list')
		
		$ionicConfigProvider.tabs.style 'standard'
		$ionicConfigProvider.tabs.position 'bottom'

		$provide.decorator '$sailsSocketBackend', ($delegate, $injector, $log) ->
			# socket connect
			io.sails.url = env.server.app.url
			io.sails.path = "#{env.path}/socket.io"
			io.sails.useCORSRouteToGetCookie = false
			socket = null
			p = new Promise (fulfill, reject) ->
				socket = io.sails.connect()
				socket.on 'connect', ->
					resource = $injector.get('resource')
					resource.User.me().$save
						online:	true
						status:	resource.User.type.status[0]
					fulfill()
				socket.on 'connect_error', ->
					reject()
				socket.on 'connect_timeout', ->
					reject()
					
			(method, url, post, callback, headers, timeout, withCredentials, responseType) ->
				p
					.then ->
						io.socket = socket
						opts = 
							method: 	method.toLowerCase()
							url: 		url
							data:		if typeof post == 'string' then JSON.parse(post) else post
							headers:	headers
						socket.request opts, (body, jwr) ->
							callback jwr.statusCode, body
					.catch $log.error
			
	.run ($cordovaDevice, $cordovaLocalNotification, $location, $http, $sailsSocket, $rootScope, $ionicModal, platform, authService, ErrorService, resource) ->
		window.alert = ErrorService.alert
			
		document.addEventListener 'deviceready', ->
			platform.pushRegister()
			
		# listen if access granted or denied in child window
		$.receiveMessage (event) ->
			data = $.deparam event.data
			if data.error
				authService.loginCancelled null, data.error
			else
				authService.loginConfirmed data
					
		$rootScope.$on '$stateChangeError', (evt, toState, toParams, fromState, fromParams, error) ->
			window.alert error
	
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
					$cordovaLocalNotification.schedule notification.payload
				else
					alert notification