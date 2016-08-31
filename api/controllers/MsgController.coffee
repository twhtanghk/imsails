 # MsgController
 #
 # @description :: Server-side logic for managing msgs
 # @help        :: See http://links.sailsjs.org/docs/controllers
_ = require 'lodash'
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
				md5 = req.param('md5', false)
				if md5 and md5 == file.prop.md5
					res.send 304, file.prop
				else
					header = 'Accept-Ranges': 'bytes'
					if file.prop.length
						_.extend header,  
							'Content-Length': file.prop.length
							'Content-Range': "bytes 0-#{file.prop.length - 1}/#{file.prop.length}"
					res.set header
					res.attachment encodeURIComponent(file.prop.filename)
					file.stream.pipe(res)
			.catch res.serverError
			
	# GET /msg/file/thumb/:id
	getThumb: (req, res) ->
		Model = actionUtil.parseModel(req)
		pk = actionUtil.requirePk(req)
		sails.services.file.thumb(Model, pk)
			.then (file) ->
				md5 = req.param('md5', false)
				if md5 and md5 == file.prop.md5
					res.send 304, file.prop
				else
					res.attachment encodeURIComponent(file.prop.filename)
					file.stream.pipe(res)
			.catch res.serverError
