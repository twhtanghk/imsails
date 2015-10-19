 # MsgController
 #
 # @description :: Server-side logic for managing msgs
 # @help        :: See http://links.sailsjs.org/docs/controllers
path = require 'path'
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
							body: sails.config.file.url
							file: files[0].fd
						return create(req, res)
					else
						return res.badRequest 'Only 1 file attachment is allowed'
			
	# GET /msg/file/:id
	getFile: (req, res) ->
		Model = actionUtil.parseModel(req)
		pk = actionUtil.requirePk(req)

		Model
			.findOne(pk)
			.then (matchingRecord) ->
				if(!matchingRecord) 
					return res.notFound('No record found with the specified `id`.');
				sails.config.file.opts.adapter(sails.config.file.opts)
					.read matchingRecord.file, (err, data) ->
						if err
							return res.serverError(err)
						res.attachment encodeURIComponent(path.basename(matchingRecord.file))
						res.send data
			.catch res.serverError