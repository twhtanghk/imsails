env = require './env.coffee'
Promise = require 'promise'

platform = ($rootScope, $cordovaInAppBrowser, $cordovaPush, $location, $http, $ionicModal, authService, $cordovaFileOpener2) ->
	# register for push notification
	pushRegister = ->
		if env.isNative()
			$cordovaPush.register env.push.gcm
				.catch alert
		
	# return promise to authenticate user
	auth = ->
		url = "#{env.oauth2().authUrl}?#{$.param(env.oauth2().opts)}"
		
		func = 
			mobile: ->
				p = new Promise (fulfill, reject) ->
					document.addEventListener 'deviceready', ->
						$cordovaInAppBrowser.open url, '_blank'
					
					$rootScope.$on '$cordovaInAppBrowser:loadstart', (e, event) ->
						authService.matchUrl event.url, fulfill, reject
					
					$rootScope.$on '$cordovaInAppBrowser:exit', (e, event) ->
						reject("The sign in flow was canceled")

				p
					.then (data) ->
						$cordovaInAppBrowser.close()
						authService.loginConfirmed data
					.catch (err) ->
						$cordovaInAppBrowser.close()
						authService.loginCancelled null, err.error
				
			browser: ->
				templateStr = """
					<ion-modal-view>
						<ion-content>
							<iframe src='#{url}'></iframe>
						</ion-content>
					</ion-modal-view>
				"""
				$rootScope.modal = $ionicModal.fromTemplate(templateStr)
				$rootScope.modal.show()
			
		func[env.platform()]()
		
	# open local file resided on the mobile device, return promise for file open
	open = (localfile, type) ->
		func =
			mobile: ->
				$cordovaFileOpener2.open(localfile, type)
				
			browser: ->
				new Promise (fulfill, reject) ->
					fulfill()
				
		func[env.platform()]()
		
	pushRegister:	pushRegister
	auth: 			auth
	open: 			open
	
config =  ($cordovaInAppBrowserProvider) ->
	opts = 
		location: 'no'
		clearsessioncache: 'no'
		clearcache: 'no'
		toolbar: 'no'
		
	document.addEventListener 'deviceready', ->
		$cordovaInAppBrowserProvider.setDefaultOptions(opts)
		cordova?.plugins.Keyboard.hideKeyboardAccessoryBar(true)
		cordova?.plugins.autoStart.enable()
		
angular.module('platform', ['ionic', 'ngCordova', 'starter.controller'])

	.config ['$cordovaInAppBrowserProvider', config]

	.factory 'platform', ['$rootScope', '$cordovaInAppBrowser', '$cordovaPush', '$location', '$http', '$ionicModal', 'authService', '$cordovaFileOpener2', platform]