 # MsgController
 #
 # @description :: Server-side logic for managing msgs
 # @help        :: See http://links.sailsjs.org/docs/controllers
_ = require 'lodash'
actionUtil = require 'sails/lib/hooks/blueprints/actionUtil'

module.exports =
	# POST /msg
	create: (req, res) ->
		Model = actionUtil.parseModel req
		data = actionUtil.parseValues(req);

		Model
			.create(data)
			.then (newInstance) ->
				Model
					.findOneById newInstance.id
					.populateAll()
			.then (newInstance) ->
				if req._sails.hooks.pubsub
					if req.isSocket
						Model.subscribe(req, newInstance);
						Model.introduce(newInstance);
					publishData = newInstance.toJSON()
					if _.isArray(newInstance)
						publishData = _.map newInstance, (instance) ->
							instance.toJSON()
					Model.publishCreate(publishData, !req.options.mirror && req);
				res.created(newInstance)
			.catch res.negotiate

	# POST /msg/file
	putFile: (req, res) ->
		req.file('file')
			.upload sails.config.file.opts, (err, files) =>
				if err
					return res.serverError(err)
				switch
					when files.length == 0
						return res.badRequest 'No file was uploaded'
					when files.length == 1
						_.extend req.options.values,
							file: files[0].fd
							file_inode: files[0].extra.fileId.toString()
						return @create(req, res)
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
