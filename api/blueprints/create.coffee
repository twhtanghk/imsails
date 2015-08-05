actionUtil = require 'sails/lib/hooks/blueprints/actionUtil'

module.exports = (req, res) ->

	Model = actionUtil.parseModel(req)
	data = actionUtil.parseValues(req)

	Model.create(data)
		.then (newInstance) ->
			if req._sails.hooks.pubsub and req.isSocket
				if Model.autoSubscribe
					Model.subscribe(req, newInstance)
					Model.introduce(newInstance)
				Model.publishCreate(newInstance, !req.options.mirror && req)
			res.created(newInstance)
		.catch res.negotiate