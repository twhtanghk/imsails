require 'util.audio'
require 'angular-xeditable'

angular
	.module 'starter.controller', [
		'ionic'
		'ngCordova'
		'starter.model'
		'platform'
		'PageableAR'
		'toastr'
		'util.audio'
		'xeditable'
	]
	.run (editableOptions) ->
		editableOptions.theme = 'bs3'

require "./common.coffee"
require("./user.coffee")(angular.module('starter.controller'))
require("./group.coffee")(angular.module('starter.controller'))
require("./roster.coffee")(angular.module('starter.controller'))
require("./msg.coffee")(angular.module('starter.controller'))
