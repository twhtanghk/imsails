Promise = require 'promise'
path = require 'path'
mime = require 'mime-types/index.js'
stream = require 'stream'
base64 = require 'base64-stream'

module.exports =
	# get file content of Model[field] from model user or group 
	get: (Model, pk, field) ->
		new Promise (fulfill, reject) ->
			Model
				.findOne(pk)
				.then (data) ->
					fulfill data[field]
				.catch reject
		
	# get {name: filename, stream: stream} of file content from gridfs
	content: (Model, pk) ->
		new Promise (fulfill, reject) ->
			Model
				.findOne(pk)
				.then (matchingRecord) ->
					if !matchingRecord 
						return reject('No record found with the specified `id`.')
					prop = {}
					try
						prop = JSON.parse matchingRecord.body
					catch error
						return
					sails.config.file.opts.adapter(sails.config.file.opts)
						.read matchingRecord.file, (err, data) ->
							if err
								return reject(err)
							readable = new stream.PassThrough()
							readable.end(data)
							fulfill 
								name:	path.basename(prop.path || matchingRecord.file)
								size:	prop.size || 0
								stream: readable
				.catch reject
				
	# get {name: filename, stream: stream} thumbnail of image file content from gridfs
	thumb: (Model, pk) ->
		new Promise (fulfill, reject) ->
			module.exports.content(Model, pk)
				.then (file) ->
					if not module.exports.isImg(file.name)
						return reject 'Attachment is not an image file'
					file.stream = sails.services.img.thumb file.stream
					fulfill file
				.catch reject
			
	# convert input file stream {name: filename, stream: stream} to base64 encoding string
	dataUrl: (file) ->
		new Promise (fulfill, reject) ->
			chunks = []
			out = file.stream.pipe(base64.encode())
			out.on 'data', (chunk) ->
				chunks.push chunk
			out.on 'end', ->
				fulfill "data:#{sails.services.file.type(file.name)};base64,#{chunks.join('')}"
		
	type: (name) ->
		mime.lookup(name)
				
	isImg: (name) ->
		(/^image/i).test module.exports.type(name)

	isAudio: (name) ->
		(/^audio/i).test module.exports.type(name)