env = require './env.coffee'

io.socket.url = env.server.app.urlRoot
io.socket.path = "#{env.path}/socket.io"
io.sails.useCORSRouteToGetCookie = false

window.oalert = window.alert
window.alert = (err) ->
	console.error err.message
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
require 'ng-img-crop'
require 'tagDirective'
require 'jq-postmessage'
require './app.coffee'
require './controller.coffee'
require './model.coffee'
require './platform.coffee'