urlparser = require 'url'

angular.module('auth', ['http-auth-interceptor'])
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
				
			loginCancelled = $delegate.loginCancelled
			$delegate.loginCancelled = (data, reason) ->
				$log.error reason
				loginCancelled(data, reason)
							
			return $delegate