angularModule =
	angular.module('starter.controller', ['ionic', 'ngCordova', 'http-auth-interceptor', 'starter.model', 'platform', 'PageableAR', 'toaster'])
	
require("./common.coffee")(angularModule)
require("./user.coffee")(angularModule)
require("./group.coffee")(angularModule)
require("./roster.coffee")(angularModule)
require("./msg.coffee")(angularModule)