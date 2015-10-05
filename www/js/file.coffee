path = require 'path'
mime = require 'mime-types/index.js'

angular.module('fileService', ['toaster', 'ngFileUpload', 'ngCordova'])
	
	.factory 'fileService', (toaster, $cordovaFileTransfer, $http, Upload, $cordovaFileOpener2) ->
	
		class FileTransfer
			
			constructor: (@local, @url, @percentage = 0) ->
				return
				
			name: ->
				if typeof @local == 'string'
					path.basename @local
				else
					@local.name
				
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
					done = =>
						@end()
						fulfill(arguments)
					error = =>
						@end()
						reject(arguments)
					data = 
						url: 	@url
						fields:	_.pick opts.data, 'to', 'type'
						file:	@local
					new Promise (fulfill, reject) =>
						Upload
							.upload(data)
							.progress @progress
							.success done
							.error error
					
			download: (opts = {}) ->
				new Promise (fulfill, reject) =>
					done = =>
						@end()
						$cordovaFileOpener2.open(@local, mime.lookup(@local))
						fulfill(arguments)
					error = =>
						@end()
						reject(arguments)
					opts = _.defaults opts, 
						responseType: 	'blob'
						headers: 		$http.defaults.headers.common
					switch device.platform
						when 'browser'
							$http.get(@url, opts)
								.then (res) =>
									contentType = res.headers('Content-type')
									saveAs new Blob([res.data], type: contentType), @local
								.catch reject
						when 'Android'
							@start()
							$cordovaFileTransfer
								.download @url, @local, opts, true
								.then done, error, @progress
				
		FileTransfer:	FileTransfer