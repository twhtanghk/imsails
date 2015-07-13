env = require './env.coffee'

io.socket.url = env.server.app.urlRoot
io.socket.path = "#{env.path}/socket.io"
io.sails.useCORSRouteToGetCookie = false

window.Promise = require 'promise'
window._ = require 'lodash'
window.$ = require 'jquery'
window.$.deparam = require 'jquery-deparam'
if env.isNative()
	window.$.getScript 'cordova.js'
	
require 'ngCordova'
require 'angular-activerecord'
require 'sails-auth'
require 'angular-touch'
require 'ng-file-upload'
require 'ngImgCrop'
require 'tagDirective'
require 'jq-postmessage'
require './app.coffee'
require './controllers/index.coffee'
require './model.coffee'
require './platform.coffee'