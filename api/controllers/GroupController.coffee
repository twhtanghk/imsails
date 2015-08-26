 # GroupController
 #
 # @description :: Server-side logic for managing groups
 # @help        :: See http://links.sailsjs.org/docs/controllers
actionUtil = require 'sails/lib/hooks/blueprints/actionUtil'

module.exports =
	# return full list of members only group
	membersOnly: (req, res) ->
		sails.models.user
			.findOne()
			.populateAll()
			.where(id: req.user.id)
			.then (user) ->
				if not user
					return res.notFound "No Members-Only group found for the authenticated user #{req.user.fullname}"
				ids = _.map user.membersOnlyGrps(), (group) ->
					group.id
				sails.models.group
					.find(ids)
					.populateAll()
					.then res.ok
					.catch res.serverError
			.catch res.serverError
			
	getPhoto: (req, res) ->
		pk = actionUtil.requirePk(req)
		Model = actionUtil.parseModel(req)
		sails.services.file.get(Model, pk, 'photo')
			.then (data) ->
				if data
					[data, type, content] = data.match(/^data:(.+);base64,(.*)$/)
					res.set('Content-Type', type)
					res.send(200, new Buffer(content, 'base64'))
				else
					res.ok()
			.catch res.serverError
			
	create: (req, res) ->
		Model = actionUtil.parseModel(req)
		data = actionUtil.parseValues(req)
			
		sails.services.crud
			.create(Model, data)
			.then (newInstance) ->
				res.created(newInstance)
			.catch (err) ->
				res.serverError
					code:	err.originalError.code
					fields:
						name: "Duplicate name '#{data.name}'"