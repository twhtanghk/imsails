Wad = require 'Wad/build/wad.js'

angular.module('audioService', ['ngCordova'])
	
	.factory 'audioService', ($cordovaDevice) ->
	
		class BrowserRecorder
			
			constructor: ->
				@media = new Wad.Poly 
					recConfig: 
						workerPath: 'lib/Wad/src/Recorderjs/recorderWorker.js'
				@mic = new Wad source: 'mic'
				@sine = new Wad source: 'sine'
				@media
					.add @mic
					.add @sine
				
			start: ->
				@media.rec.clear()
				@media.rec.record()
				@sine.play()
				msg = =>
					@sine.stop()
					@mic.play()
				_.delay msg, 1000
				
			stop: ->
				@mic.stop()
				@media.rec.stop()
				
			file: (name) ->
				new Promise (fulfill, reject) =>
					@media.rec.exportWAV (blob) ->
						_.extend blob,
							name:			 	name
							lastModifiedDate: 	new Date()
						fulfill blob
					
		class NativeRecorder
			
			constructor: ->
				document.addEventListener 'deviceready', =>
					@media = new Media 'cdvfile://localhost/temporary/audio.wav'
				
			start: ->
				@media.startRecord()
				
			stop: ->
				@media.stopRecord()
				
			file: (name) ->
				@media
				
		recorder = ->
			switch $cordovaDevice.getPlatform()
				when 'browser'
					new BrowserRecorder()
				else
					new NativeRecorder()
					
		recorder: recorder()