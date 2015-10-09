env = require './env.coffee'

angular.module('starter', ['ionic', 'starter.controller', 'starter.model', 'locale', 'auth', 'ngTagEditor', 'ActiveRecord', 'ngFileUpload', 'ngTouch', 'ngImgCrop', 'ngFancySelect', 'ngIcon', 'templates', 'ionic-press-again-to-exit', 'toaster'])
	
	# default page url
	.config ($urlRouterProvider) ->
		$urlRouterProvider.otherwise('/roster/list')
		
	# ionic default settings
	.config ($ionicConfigProvider) ->
		$ionicConfigProvider.tabs.style 'standard'
		$ionicConfigProvider.tabs.position 'bottom'

	# define sails socket backend setting and initialie the backend
	.config ($provide) ->
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
	
	# define showAction method for ionic action sheet 
	.config ($provide) ->
		$provide.decorator '$ionicActionSheet', ($delegate) ->
			###
				opts:
					titleText:	'action title'
					action: [
						{type: 'button', text: 'button label', cb: func, show: true|false}
						...
						{type: 'destructive', text: 'Delete', cb: func, show: true|false}
						{type: 'cancel', text': 'Cancel', cb: func, show true|false}
					]
			###
			$delegate.showAction = (opts) ->
				newopts = _.extend {}, _.pick(opts, 'titleText')
				buttons = _.where(opts.action, type: 'button', show: true)
				newopts.buttons = _.map buttons, (button) ->
					_.pick button, 'text'
				newopts.buttonClicked = (index) ->
					buttons[index]?.cb()
				destructive = _.find(opts.action, type: 'destructive', show: true)
				if not _.isUndefined(destructive)
					newopts.destructiveText = destructive.text
					newopts.destructiveButtonClicked = destructive.cb
				cancel = _.find(opts.action, type: 'cancel', show: true)
				if not _.isUndefined(cancel)
					newopts.cancelText = cancel.text
					newopts.cancel = cancel.cb
				$delegate.show newopts
				
			return $delegate
					
	# press again to exit
	.run ($translate, $ionicPressAgainToExit, toaster) ->
		$ionicPressAgainToExit ->
			$translate 'Press again to exit'
				.then (text) ->
					toaster.pop
						type:			'info'
						body:			text
						bodyOutputType: 'trustedHtml'
						timeout:		2000
					
	# auth
	.run ($rootScope, platform, authService) ->
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
		
	# image crop
	.run ($rootScope, $ionicModal) ->
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
					
	# push notification
	.run ($rootScope, $cordovaPush, $cordovaLocalNotification, $cordovaDevice, resource) ->
		document.addEventListener 'deviceready', ->
			if $cordovaDevice.getPlatform() != 'browser'
				$cordovaPush.register env.push.gcm
					.catch alert
		
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

	# local notifiction
	.run ($rootScope) ->
		$rootScope.$on '$cordovaLocalNotification:click', (event, notification, state) ->
			try 
				data = JSON.parse notification.data
				location.hash = data.url
			catch err
				alert err