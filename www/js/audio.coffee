Wad = require 'Wad/build/wad.js'
				
angular.module('audioService', ['ngCordova'])
	
	.config ($sceDelegateProvider, $compileProvider) ->
		
		$sceDelegateProvider.resourceUrlWhitelist ['self', 'https://mob.myvnc.com/**', 'filesystem:**']
		$compileProvider.imgSrcSanitizationWhitelist /^\s*((https?|ftp|file|blob|filesystem):|data:image\/)/
		
	.factory 'audioService', ($cordovaDevice) ->
	
		beep = (ms, cb) ->
			sine = new Wad source: 'sine'
			sine.play()
			callback = ->
				sine.stop()
				cb()
			_.delay callback, ms 
				
		class Recorder
			
			constructor: ->
				@media = new Wad.Poly 
					recConfig: 
						workerPath: 'lib/Wad/src/Recorderjs/recorderWorker.js'
				@mic = new Wad
					source: 		'mic'
				@media
					.add @mic
				
			start: ->
				beep 1000, =>
					@media.rec.clear()
					@media.output.disconnect(@media.destination)
					@media.rec.record()
					@mic.play()
				
			stop: ->
				beep 500, =>
					@mic.stop()
					@media.rec.stop()
					@media.output.connect(@media.destination)
				
			file: (name) ->
				new Promise (fulfill, reject) =>
					@media.rec.exportWAV (blob) ->
						_.extend blob,
							name:			 	name
							lastModifiedDate: 	new Date()
						fulfill blob

		class Player
		
			start: (url) ->
				@audio = new Wad source: url
				@audio.play()
				
			stop: ->
				@audio.stop()
			 
		recorder:	new Recorder()
		player:		new Player()