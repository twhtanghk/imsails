 # RosterController
 #
 # @description :: Server-side logic for managing rosters
 # @help        :: See http://links.sailsjs.org/docs/controllers
actionUtil = require 'sails/lib/hooks/blueprints/actionUtil'

module.exports =
	create: (req, res) ->
		Model = actionUtil.parseModel(req)
		data = actionUtil.parseValues(req)
		cond = 
			jid: 		data.jid
			createdBy:	data.createdBy.id
		Model.findOrCreate(cond, data)
			.then (newInstance) ->
				if req._sails.hooks.pubsub
					if req.isSocket
						Model.subscribe(req, newInstance)
						Model.introduce(newInstance)
					Model.publishCreate(newInstance, !req.options.mirror && req)
				res.created(newInstance)
			.catch res.negotiate