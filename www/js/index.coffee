env = require './env.coffee'

io.socket.path = "#{env.path}/socket.io"

window.oalert = window.alert
window.alert = (err) ->
	window.oalert err.data.error
window.Promise = require 'promise'
window._ = require 'lodash'
window.$ = require 'jquery'
window.$.deparam = require 'jquery-deparam'
if env.isNative()
	window.$.getScript 'cordova.js'
	
require 'ngCordova'
require 'angular-activerecord'
require 'angular-http-auth'
require 'angular-touch'
require 'ng-file-upload'
require 'ng-img-crop'
require 'tagDirective'
require './app.coffee'
require './controller.coffee'
require './model.coffee'
require './platform.coffee'