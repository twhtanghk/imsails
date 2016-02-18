_ = require 'lodash'
path = require 'path'

angular.module('util.file', ['ng', 'toaster'])

	.factory 'fileService', ($http, toaster) ->

		class Progress
				constructor: (@name, @percentage = 0) ->
					@id = toaster.pop
						type:	'info'
						body: =>
							template:	'templates/progress.html'
							data:		@
						bodyOutputType:	'templateWithData'
						timeout:		0
						
				end: =>
					toaster.clear @id
					
				progress: (event) =>
					@percentage = event.loaded / event.total
				
		deviceReady = ->
			new Promise (fulfill, reject) ->
				document.addEventListener 'deviceready', ->
					fulfill()
			
		fsReady = ->
			new Promise (fulfill, reject) -> 
			
				opts = 
					persistent:		true
					storageSize:	0 # storage size in bytes 
					concurrency:	3 # how many concurrent uploads/downloads?
					Promise: 		require 'bluebird'
				
				if window.device.platform == 'Android'
					_.extend opts, fileSystem: cordova.file.externalDataDirectory
					
				fs = CordovaPromiseFS opts
				
				defaultOpts =
					headers: 		$http.defaults.headers.common
					trustAllHosts:	true
					
				# clear all subfolders and files on the filesystem
				fs.clear = ->
					Promise.all [
						fs
							.list '', 'f'
							.map fs.remove
						fs
							.list '', 'd'
							.map fs.removeDir
					]
								
				# override create to clear the filesystem if quota exceeded
				create = fs.create
				fs.create = (filename) ->
					create filename
						.catch (e) ->
							if e.code == FileError.QUOTA_EXCEEDED_ERR
								fs
									.clear()
									.then ->
										create filename
							else
								Promise.reject e
				
				# override upload to send request with oauth2 token and show progress	
				upload = fs.upload
				fs.upload = (source, dest, options = {}, onprogress) ->
					_.defaults options, defaultOpts
					transfer = new Progress source
					upload source, dest, options, onprogress || transfer.progress
						.then transfer.end, transfer.end
					
				# upload file entry and show progress
				fs.uploadFile = (entry, dest, opts = {}, onprogress) ->
					_.defaults opts, defaultOpts
					new Promise (fulfill, reject) =>
						# define data
						data = new FormData()
						_.each opts.data, (value, key) ->
							data.append key, value
						data.append 'file', entry, entry.name
						
						# define header
						xhr = new XMLHttpRequest()
						xhr.open 'post', dest, true
						_.each opts.headers, (value, key) ->
							xhr.setRequestHeader key, value
							
						# send upload request
						transfer = new Progress entry.name
						_fulfill = ->
							transfer.end()
							fulfill()
						_reject = ->
							transfer.end()
							reject()	
						xhr.upload.addEventListener 'loadend', _fulfill
						xhr.upload.addEventListener 'error', _reject
						xhr.upload.addEventListener 'progress', onprogress || transfer.progress
						xhr.send data
					
				# override download to send request with oauth2 token
				download = fs.download
				fs.download = (source, dest, options = {}, onprogress) ->
					_.defaults options, defaultOpts
					download source, dest, options, onprogress
						
				fulfill fs
			
		Progress:	Progress
		fs:			deviceReady().then fsReady