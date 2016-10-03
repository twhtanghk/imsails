Promise = require 'bluebird'
path = require 'path'
mime = require 'mime-types/index.js'
stream = require 'stream'
base64 = require 'base64-stream'
digest = require 'digest-stream'
miss = require 'mississippi'
streamifier = require 'streamifier'

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
		getMsg = (id) ->
			Model.findOne(id)
				.then (msg) ->
					if !msg
						Promise.reject 'No record found with the specified `id`.'
					Promise.resolve msg
		getFile = (msg) ->
			sails.models.gridfs.findOne filename: msg.file
		getReader = (file) ->
			new Promise (resolve, reject) ->
				sails.config.file.opts.adapter sails.config.file.opts
					.read file.metadata.fd, (err, data) ->
						if err
							return reject err
						readable = new stream.PassThrough()
						readable.end(data)
						resolve readable

		getMsg(pk).then (msg) ->
			getFile(msg).then (file) ->
				getReader(file).then (stream) ->
					Promise.resolve
						prop:	file
						stream:	stream

	# get {name: filename, stream: stream} thumbnail of image file content from gridfs
	thumb: (Model, pk) ->
		module.exports.content(Model, pk)
			.then (file) ->
				if module.exports.isImg(file.prop) or module.exports.isVideo(file.prop)
					file.prop.filename = sails.services.file.thumbName file.prop.filename
					thumbnail = ->
						if module.exports.isImg file.prop
							file.stream
								.pipe sails.services.thumb.img()
						else
							file.stream
								.pipe sails.services.thumb.video(), end: false
					new Promise (resolve, reject) ->
						thumbnail()
							.pipe digest 'md5', 'hex', (digest, length) ->
								file.prop.length = length
								file.prop.md5 = digest
							.pipe miss.concat (buffer) ->
								file.stream = streamifier.createReadStream buffer
								resolve file
				else
					Promise.reject 'Attachment is not an image/video file'
			.catch Promise.reject

	type: (inode) ->
		inode?.contentType

	isImg: (inode) ->
		(/^image/i).test @type inode

	isAudio: (inode) ->
		(/^audio/i).test @type inode

	isVideo: (inode) ->
		(/^video/i).test @type inode

	thumbName: (filename) ->
		"thumb.#{filename}"
