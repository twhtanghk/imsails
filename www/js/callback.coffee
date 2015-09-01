$ = require 'jquery'
$.deparam = require 'jquery-deparam'

require './auth.coffee'
require 'sails-auth'
require 'angularSails'
require 'jq-postmessage'

angular.module('starter', ['ionic', 'auth'])
	.run ($location, authService) ->
		# notify parent window if access_token is available or access denied
		url = $location.absUrl()
		resolve = (data) ->
			$.postMessage data, url
		reject = (err) ->
			$.postMessage err, url
		authService.matchUrl $location.absUrl(), resolve, reject