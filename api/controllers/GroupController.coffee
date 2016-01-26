 # GroupController
 #
 # @description :: Server-side logic for managing groups
 # @help        :: See http://links.sailsjs.org/docs/controllers
actionUtil = require 'sails/lib/hooks/blueprints/actionUtil'

module.exports =
	# list members only groups with current login user as member
	membersOnly: (req, res) ->
		sails.models.user
			.findOne()
			.where(id: req.user.id)
			.populateAll()
			.then (user) ->
				if not user
					return res.notFound()
				req.options.where = id: _.map user.membersOnlyGrps(), (group) ->
					group.id
				sails.services.crud
					.find(req)
					.then res.ok
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
		sails.services.crud
			.create(req)
			.then (newInstance) ->
				res.created(newInstance)
			.catch (err) ->
				res.serverError
					code:	err.originalError.code
					fields:
						name: "Duplicate name '#{data.name}'"
						
	exit: (req, res) ->
		pk = actionUtil.requirePk(req)
		Model = actionUtil.parseModel(req)
		req.user.moderatorGrps.remove pk
		req.user.memberGrps.remove pk
		req.user
			.save()
			.then (user) ->
				Model
					.findOne()
					.where({id: pk, name: '!': sails.config.authGrp}) # exclude authGrp from user to leave the group
					.populateAll()
					.then (group) ->
						if !group
							return res.notFound()
						if sails.hooks.pubsub
							Model.publishRemove(pk, 'moderators', req.user.id, !sails.config.blueprints.mirror && req)
							Model.publishRemove(pk, 'members', req.user.id, !sails.config.blueprints.mirror && req)
						return res.ok(group)
			.catch res.serverError
	
	# list groups created by me
	findByMe: (req, res)->
		opts = actionUtil.opts req
		opts.model
			.find()
			.then res.ok
			.catch res.serverError
			
	findOneByName: (req, res)->
		opts = actionUtil.opts req
		opts.model
			.findOne()
			.where opts.where
			.populateAll()
			.then (group) ->
				if group
					res.ok group
				else
					res.notFound()
			.catch res.serverError			