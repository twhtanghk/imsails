require 'util.audio'

angularModule =
	angular.module('starter.controller', ['ionic', 'ngCordova', 'starter.model', 'platform', 'PageableAR', 'toaster', 'util.audio'])
	
require("./common.coffee")(angularModule)
require("./user.coffee")(angularModule)
require("./group.coffee")(angularModule)
require("./roster.coffee")(angularModule)
require("./msg.coffee")(angularModule)