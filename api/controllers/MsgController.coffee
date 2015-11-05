 # MsgController
 #
 # @description :: Server-side logic for managing msgs
 # @help        :: See http://links.sailsjs.org/docs/controllers
actionUtil = require 'sails/lib/hooks/blueprints/actionUtil'
create = require 'sails/lib/hooks/blueprints/actions/create'

module.exports =
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
							body: JSON.stringify
								path:	files[0].fd
								size:	files[0].size
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
				# define default range of partial file to be sent
				index =
					start:	0
					end:	file.size - 1
				# update range if request for partial file content
				if req.headers.range
					range = req.headers.range
					parts = range.replace(/bytes=/, "").split("-")
					index.start = parseInt parts[0]
					if parts[1]
						index.end = parseInt parts[1]
				
					header = 'Accept-Ranges': 'bytes'
					_.extend header,  
						'Content-Length': index.end - index.start + 1
						'Content-Range': "bytes #{index.start}-#{index.end}/#{file.size}"
					res.status 206
				
				res.set header
				res.attachment encodeURIComponent(file.name)
				partial = new sails.services.stream.Partial index.start, index.end
				file.stream.pipe(partial).pipe(res)
			.catch res.serverError
			
	# GET /msg/file/thumb/:id
	getThumb: (req, res) ->
		Model = actionUtil.parseModel(req)
		pk = actionUtil.requirePk(req)
		sails.services.file.thumb(Model, pk)
			.then (file) ->
				res.attachment encodeURIComponent(file.name)
				file.stream.pipe(res)
			.catch res.serverError