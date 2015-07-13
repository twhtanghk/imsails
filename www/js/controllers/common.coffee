env = require '../env.coffee'
_ = require 'lodash'
urlparser = require 'url'

service = 
	alert: ($ionicPopup, $timeout) ->
		alert: (msg) ->
			popup = $ionicPopup.alert template: msg
			popup.then ->
				return
			$timeout popup.close, 3000
			
	oauth: ($http, $sailsSocket, authService) ->
		# set authorization header once oauth2 token is available
		loginConfirmed: (data, configUpdater) ->
			if data?
				$http.defaults.headers.common.Authorization = "Bearer #{data.access_token}"
				$sailsSocket.defaults.headers.common.Authorization = "Bearer #{data.access_token}"
				authService.loginConfirmed null, (config) ->
					config.headers = _.omit config.headers, 'Authorization'
					return config
			
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
	
ctrl = 
	menu: ($scope, resource) ->
		_.extend $scope,
			env: env
			resource: resource
			model: resource.User.me()
			exit: ->
				io.socket.disconnect()
				navigator.app.exitApp()
				
		$scope.$watch 'model.status', (newvalue, oldvalue) ->
			if newvalue != oldvalue
				$scope.model.$save()
	
module.exports = (angularModule) ->
	angularModule
		.factory 'AlertService', ['$ionicPopup', '$timeout', service.alert]
		.factory 'OAuthService', ['$http', '$sailsSocket', 'authService', service.oauth]
		.controller 'MenuCtrl', ['$scope', 'resource', ctrl.menu]