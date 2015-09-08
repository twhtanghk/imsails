env = require './env.coffee'

window.Promise = require 'promise'
window._ = require 'lodash'
window.$ = require 'jquery'
window.$.deparam = require 'jquery-deparam'
window.saveAs = require('file-saver.js').saveAs
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
require './templates.js'
require './app.coffee'
require './controllers/index.coffee'
require './model.coffee'
require './platform.coffee'
require './auth.coffee'