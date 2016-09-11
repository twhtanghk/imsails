_ = require 'lodash'

angular
	.module 'util.file', [
		'ng'
		'toastr'
	]

	.config (toastrConfig) ->
		_.extend toastrConfig,
			templates:
				toast: 'templates/progress.html'

	.factory 'fileService', ($http, toastr) ->

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
					when window.device.platform == 'Android'
						return resolve()

		fsReady = ->
			if window.device.platform == 'Android'
				_.extend opts, fileSystem: cordova.file.externalDataDirectory

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
						.catch (err) =>
							if err.http_status == 304
								# not modified, reference the cached copy
								Promise.resolve()
							else
								# it is mostly filesystem quota exceeded
								Promise.reject new Error 'fileystem quota exceeded, please see <a href="https://developer.chrome.com/apps/offline_storage#reset">here</a> to clear the filesystem'

				resolve fs

		Progress:	Progress
		fs: deviceReady()
			.then quotaReady
			.then fsReady
