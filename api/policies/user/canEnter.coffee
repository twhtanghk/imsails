actionUtil = require 'sails/lib/hooks/blueprints/actionUtil'

# check if authenticated user is allowed to enter the room  
module.exports = (req, res, next) ->
	
	values = actionUtil.parseValues(req)
	to = values.to
	
	if not sails.services.jid.isMuc to
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
					if req.user.canEnter group
						return next()
					else
						return res.serverError msg: "Not authorized to enter room #{group.name}"
				else
					return res.notFound()
			.catch res.serverError