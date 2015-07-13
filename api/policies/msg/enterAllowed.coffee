_ = require 'lodash'
actionUtil = require 'sails/lib/hooks/blueprints/actionUtil'

# check if authenticated user is allowed to enter the room  
module.exports = (req, res, next) ->
	
	values = actionUtil.parseValues(req)
	type = values.type
	to = values.to
	
	if type == 'chat'
		sails.models.user
			.findOne jid: to
			.then (user) ->
				if user
					return next()
				else
					return res.notFound()
			.catch res.serverError
	else
		sails.models.group
			.findOne jid: to
			.populateAll()
			.then (group) ->
				if group
					if group.enterAllowed req.user
						return next()
					else
						return res.serverError "Not authorized to enter room #{group.name}"
				else
					return res.notFound()
			.catch res.serverError