 # UserController
 #
 # @description :: Server-side logic for managing users
 # @help        :: See http://links.sailsjs.org/docs/controllers
actionUtil = require 'sails/lib/hooks/blueprints/actionUtil'

module.exports =
	getPhoto: (req, res) ->
		pk = actionUtil.requirePk(req)
		Model = actionUtil.parseModel(req)
		sails.services.file.get(Model, pk, 'photoUrl')
			.then (data) ->
				if data
					[data, type, content] = data.match(/^data:(.+);base64,(.*)$/)
					res.set('Content-Type', type)
					res.send(200, new Buffer(content, 'base64'))
				else
					res.ok()
			.catch res.serverError