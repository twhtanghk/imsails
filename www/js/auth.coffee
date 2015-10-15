env = require './env.coffee'

angular.module('auth', ['ng', 'http-auth-interceptor', 'ngCordovaOauth'])
	
	.config ($provide) ->
		$provide.decorator 'authService', ($delegate, $log, $http, $sailsSocket) ->
			loginConfirmed = $delegate.loginConfirmed
			# set authorization header once oauth2 token is available
			$delegate.loginConfirmed = (data, configUpdater) ->
				if data?
					$http.defaults.headers.common.Authorization = "Bearer #{data.access_token}"
					$sailsSocket.defaults.headers.common.Authorization = "Bearer #{data.access_token}"
					loginConfirmed null, (config) ->
						config.headers = _.omit config.headers, 'Authorization'
						return config
				
			return $delegate
			
	.run ($rootScope, authService, $cordovaOauth) ->
		opts = env.oauth2().opts
		auth = ->
			$cordovaOauth.mob(opts.client_id, opts.scope)
				.then (data) ->
					authService.loginConfirmed data
				.catch (err) ->
					authService.loginCancelled null, err
		once = _.once auth  
		$rootScope.$on 'event:auth-forbidden', once
		$rootScope.$on 'event:auth-loginRequired', once
		$rootScope.$on 'event:auth-loginConfirmed', ->
			# auth is successfully called once, new auth process for token expiry
			once = _.once auth
		$rootScope.$on 'event:auth-loginCancelled', ->
			# auth is successfully called once, new auth process for token expiry
			once = _.once auth