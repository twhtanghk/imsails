Promise = require 'promise'
path = require 'path'
mime = require 'mime-types/index.js'
stream = require 'stream'
im = require 'imagemagick-stream'

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
					sails.config.file.opts.adapter(sails.config.file.opts)
						.read matchingRecord.file, (err, data) ->
							if err
								return reject(err)
							readable = new stream.PassThrough()
							readable.end(data)
							fulfill name: path.basename(matchingRecord.file), stream: readable
				.catch reject
				
	# get {name: filename, stream: stream} thumbnail of image file content from gridfs
	thumb: (Model, pk) ->
		new Promise (fulfill, reject) ->
			module.exports.content(Model, pk)
				.then (file) ->
					if not module.exports.isImg(file.name)
						return reject('Attachment is not an image file')
					file.stream = file.stream.pipe(im().resize(sails.config.file.img.resize))
					fulfill file
				.catch reject
		
	type: (name) ->
		mime.lookup(name)
				
	isImg: (name) ->
		(/image/i).test module.exports.type(name)