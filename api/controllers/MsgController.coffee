 # MsgController
 #
 # @description :: Server-side logic for managing msgs
 # @help        :: See http://links.sailsjs.org/docs/controllers
actionUtil = require 'sails/lib/hooks/blueprints/actionUtil'
create = require 'sails/lib/hooks/blueprints/actions/create'
base64 = require 'base64-stream'

# convert input file stream {name: filename, stream: stream} to base64 encoding string
dataUrl = (file) ->
	new Promise (fulfill, reject) ->
		chunks = []
		out = file.stream.pipe(base64.encode())
		out.on 'data', (chunk) ->
			chunks.push chunk
		out.on 'end', ->
			fulfill "data:#{sails.services.file.type(file.name)};base64,#{chunks.join('')}"		
		
module.exports =
	find: (req, res) ->
		sails.services.crud
			.find(req)
			.then (data) ->
				# to add dataUrl field for all image attachment 
				all = Promise.all _.map data.results, (msg) ->
					new Promise (fulfill, reject) ->
						result = msg.toJSON()
						if msg.isImg()
							sails.services.file
								.thumb(sails.models.msg, msg.id)
								.then (file) ->
									dataUrl(file)
										.then (url) ->
											_.extend result.file, thumbUrl: url
											fulfill result
										.catch reject
								.catch reject
						else
							fulfill result
				all
					.then (results) ->
						data.results = results
						res.ok(data) 
					.catch res.serverError
			.catch res.serverError
						
	# POST /msg/file
	putFile: (req, res) ->
		req.file('file')
			.upload sails.config.file.opts, (err, files) ->
				if err
					return res.serverError(err)
				switch
					when files.length == 0
						return res.badRequest 'No file was uploaded'
					when files.length == 1
						_.extend req.options.values,
							body: sails.config.file.url
							file: files[0].fd
						return create(req, res)
					else
						return res.badRequest 'Only 1 file attachment is allowed'
			
	# GET /msg/file/:id
	getFile: (req, res) ->
		Model = actionUtil.parseModel(req)
		pk = actionUtil.requirePk(req)
		sails.services.file.content(Model, pk)
			.then (file) ->
				res.attachment encodeURIComponent(file.name)
				file.stream.pipe(res)
			.catch res.serverError
			
	# GET /msg/file/thumb/:id
	getThumb: (req, res) ->
		Model = actionUtil.parseModel(req)
		pk = actionUtil.requirePk(req)
		sails.services.file.thumb(Model, pk)
			.then (file) ->
				dataUrl(file).then (url) ->
					res.json name: file.name, dataUrl: url
			.catch res.serverError