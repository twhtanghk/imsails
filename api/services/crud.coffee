Promise = require 'promise'
actionUtil = require 'sails/lib/hooks/blueprints/actionUtil'

module.exports = 
	create: (Model, data) ->
		new Promise (fulfill, reject) ->
			Model.create(data)
				.then (newInstance) ->
					if req._sails.hooks.pubsub
						if req.isSocket
							Model.subscribe(req, newInstance);
							Model.introduce(newInstance);
						Model.publishCreate(newInstance, !req.options.mirror && req)
					fulfill(newInstance)
				.catch reject