path = require 'path'
mime = require 'mime-types/index.js'

angular.module('util.file', ['toaster', 'ngCordova'])
	
	.factory 'fileService', (toaster, $cordovaFileTransfer, $http, $cordovaFileOpener2, $log) ->

		class FS
		
			_fs = [null, null]
		
			constructor: (@fs) ->
				@name = @fs.name
				@root = @fs.root
				
			@createDir: (current, folders) ->
				# remove './a/b' or '/a//b'
				if folders[0] == '.' || folders[0] == ''
					folders = folders.slice 1
				new Promise (fulfill, reject) ->
					if folders.length
						success = (entry) ->
							FS.createDir entry, folders.slice(1)
								.then fulfill, reject
						current.getDirectory folders[0], create: true, success, reject
					else
						fulfill current
				
			dirEntry: (dir) ->
				new Promise (fulfill, reject) =>
					@root.getDirectory dir, fulfill, reject 
			
			fileEntry: (file) ->
				new Promise (fulfill, reject) =>
					@root.getFile file, fulfill, reject 
			
			entry: (path) ->
				new Promise (fulfill, reject) ->
					fileEntry(path)
						.then fulfill
						.catch ->
							dirEntry(path)
								.then fulfill
								.catch reject
					
			# create file
			create: (fullpath, opts = {create: true}) ->
				new Promise (fulfill, reject) =>
					FS.createDir @root, path.dirname(fullpath).split '/'
						.then =>
							@root.getFile fullpath, opts, fulfill, reject
						.catch reject
					
			# create directory
			mkdir: (fullpath, opts = {create: true}) ->
				FS.createDir @root, fullpath.split '/'
				
			# read file content and return file content once ready
			read: (file) ->
				new Promise (fulfill, reject) =>
					@fileEntry(file)
						.then (entry) ->
							reader = new FileReader()
							reader.onload = (content) ->
								fulfill content
							reader.readAsBinaryString entry
						.catch reject
							
			# list files under the specified directory
			list: (dir) ->
				new Promise (fulfill, reject) =>
					@dirEntry(dir)
						.then (entry) ->
							reader = entry.createReader()
							read = reader.readEntries (results) ->
								new Promise (success, error) ->
									if results.length
										read()
											.then (next) ->
												success _.union(results, next).sort()
											.catch error
									else
										success []
							read().then fulfill, reject
						.catch reject
		
			write: (file, blob) ->
				new Promise (fulfill, reject) =>
					@fileEntry(file)
						.then (entry) ->
							write = (writer) ->
								writer.onwriteend ->
									fulfill()
								writer.onwriteerror reject
								writer.write blob
							entry.createWriter write, reject
						.catch reject
				
			remove: (path, recursive = false) ->
				new Promise (fulfill, reject) =>
					@entry(path)
						.then (entry) ->
							if entry.isFile
								@fileEntry(path)
									.then (entry) ->
										entry.remove fulfill, reject
							else
								@dirEntry(path)
									.then (entry) ->
										if rescursive
											entry.removeRecursively path, fulfill, reject
										else
											entry.remove path, fulfill, reject
						.catch reject

			@requestFileSystem: (type = window.TEMPORARY, size = 0) ->
				new Promise (fulfill, reject) ->
					document.addEventListener 'deviceready', ->
						window.requestFileSystem  = window.webkitRequestFileSystem || window.requestFileSystem
						_fs[type] ?= new Promise (fulfill, reject) ->
							success = (fs) ->
								fulfill new FS fs
							window.requestFileSystem type, size, success, reject
						_fs[type].then fulfill, reject
						
		class FileTransfer
			
			constructor: (@entry, @url, @percentage = 0) ->
				return
				
			start: ->
				@id = toaster.pop
					type:			'info'
					body: =>
						template:	"templates/progress.html"
						data:		@
					bodyOutputType: 'templateWithData'
					timeout:		0
					
			end: =>
				toaster.clear(@id)
				
			progress: (event) =>
				@percentage = event.loaded / event.total
				
			upload: (opts = {}) ->
				@start()
				new Promise (fulfill, reject) =>
					# define data
					data = new FormData()
					_.each _.pick(opts.data, 'to', 'type'), (value, key) ->
						data.append key, value
					data.append 'file', @entry, @entry.name
					
					# define header
					xhr = new XMLHttpRequest()
					xhr.open 'post', @url, true
					_.each $http.defaults.headers.common, (value, key) ->
						xhr.setRequestHeader key, value
						
					# send upload request
					xhr.upload.addEventListener 'loadend', =>
						@end()
						fulfill arguments
					xhr.upload.addEventListener 'error', =>
						@end()
						reject arguments
					xhr.upload.addEventListener 'progress', @progress
					xhr.send data
					
			download: (opts = {}, progress = false) ->
				new Promise (fulfill, reject) =>
					opts = _.defaults opts, 
						responseType: 	'blob'
						headers: 		$http.defaults.headers.common
					$http.get(@url, opts)
						.then (res) =>
							writeProgress = (writer) =>
								writer.onwritestart = @start
								writer.onwriteend = =>
									@end()
									fulfill()
								writer.onwriteerror = =>
									@end
									reject arguments
								writer.onprogress = @progress
								writer.write res.data
							write =  (writer) =>
								writer.onwriteend =	fulfill
								writer.onwriteerror = reject
								writer.write res.data
							@entry.createWriter writeProgress, reject
						.catch reject
						
			saveAs: ->
				opts = _.defaults opts, 
					responseType: 	'blob'
					headers: 		$http.defaults.headers.common
				$http.get(@url, opts)
					.then (res) =>
						contentType = res.headers('Content-type')
						saveAs new Blob([res.data], type: contentType), @entry.name
					.catch alert

		FileSystem:		FS
		FileTransfer:	FileTransfer