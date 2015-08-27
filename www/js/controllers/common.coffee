env = require '../env.coffee'
_ = require 'lodash'
urlparser = require 'url'
util = require 'util'

service = 
	error: ($ionicPopup, $timeout, $log) ->
		alert: (err) ->
			$log.error util.inspect(err.data.msg)
			popup = $ionicPopup.alert template: err.data.msg
			popup.then ->
				return
			$timeout popup.close, 3000
			
		formErr: (form, err) ->
			_.each err.data.fields, (value, key) ->
				_.extend form[key].$error, server: err.data.fields[key]
			
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
	state: ($stateProvider) ->
		$stateProvider.state 'app',
			url: ""
			abstract: true
			templateUrl: "templates/menu.html"
	
	menu: ($scope, resource) ->
		_.extend $scope,
			env: env
			resource: resource
			model: resource.User.me()
			exit: ->
				io.socket.disconnect()
				navigator.app.exitApp()
		
		resource.User.me().promise.then ->		
			$scope.$watch 'model.status', (newvalue, oldvalue) ->
				if newvalue != oldvalue
					data = new resource.User id: $scope.model.id
					data.$save(status: $scope.model.status).catch alert
	
module.exports = (angularModule) ->
	angularModule
		.factory 'ErrorService', ['$ionicPopup', '$timeout', '$log', service.error]
		.factory 'OAuthService', ['$http', '$sailsSocket', 'authService', service.oauth]
		.config ['$stateProvider', ctrl.state]
		.controller 'MenuCtrl', ['$scope', 'resource', ctrl.menu]