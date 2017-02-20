_ = require 'lodash'
path = require 'path'

angular
	.module 'util.file', [
		'ng'
		'toastr'
	]

	.config (toastrConfig) ->
		_.extend toastrConfig,
			templates:
				toast: 'templates/progress.html'

	.factory 'fileService', ($http, $log, toastr) ->

		class Progress
			showProgress:	true

			constructor: (@name, @percentage = 0) ->
				@toast = toastr.info '', @name,
					allowHtml: true
					extraData: @
					autoDismiss: false
					timeOut: 0

			end: =>
				toastr.clear @toast

			progress: (event) =>
				if event.lengthComputable && event.total > 0
					@showProgress = true
					@percentage = Math.round event.loaded / event.total * 100
					@toast.scope.$apply()
				else
					@showProgress = false

		opts =
			persistent:		true
			storageSize:	1024 * 1024 * 1024 # storage size in bytes
			concurrency:	3 # how many concurrent uploads/downloads?
			Promise: 		require 'bluebird'

		deviceReady = ->
			new Promise (fulfill, reject) ->
				document.addEventListener 'deviceready', ->
					fulfill()

		quotaReady = ->
			new Promise (resolve, reject) ->
				switch true
					when window.device.platform == 'browser'
						return navigator.webkitPersistentStorage.requestQuota opts.storageSize, resolve, reject
					else
						return resolve()

		fsReady = ->
			switch true
				when window.device.platform == 'Android'
					_.extend opts, fileSystem: cordova.file.externalDataDirectory
				when window.device.platform == 'iOS'
					_.extend opts, fileSystem: cordova.file.dataDirectory

			new Promise (resolve, reject) ->
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
						data.append 'file', entry, path.basename entry.name

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
						_reject = (err) ->
							transfer.end()
							reject new Error err
						xhr.addEventListener 'readystatechange', (e) ->
							if xhr.readyState = 4
								if xhr.status == 201
									_fulfill()
								else
									_reject xhr.statusText
						xhr.upload.addEventListener 'error', _reject
						xhr.upload.addEventListener 'progress', onprogress || transfer.progress
						xhr.send data

				# override download to send request with oauth2 token
				download = fs.download
				fs.download = (source, dest, options = {}, onprogress) ->
					_.defaults options, defaultOpts
					download source, dest, options, onprogress
						.catch $log.error

				# overried exists
				exists = fs.exists
				fs.exists = (path) ->
					exists path
						.catch (err) ->
							if err.code == 8
								Promise.resolve false
							else
								Promise.reject err

				resolve fs

		Progress:	Progress
		fs: deviceReady()
			.then quotaReady
			.then fsReady
