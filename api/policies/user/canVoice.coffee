_ = require 'lodash'
actionUtil = require 'sails/lib/hooks/blueprints/actionUtil'

# check if authenticated user is granted with voice  
module.exports = (req, res, next) ->
	
	values = actionUtil.parseValues(req)
	type = values.type
	to = values.to
	
	if not sails.services.jid.isMuc(to)
		sails.models.user
			.findOne(jid: to)
			.populateAll()
			.then (user) ->
				if user
					return next()
				else
					return res.notFound values.to
			.catch res.serverError
	else
		sails.models.group
			.findOne(jid: to)
			.populateAll()
			.then (group) ->
				if group
					if req.user.canVoice group
						return next()
					else
						return res.serverError msg: "Not granted with voice for room #{group.name}"
				else
					return res.notFound()
			.catch res.serverError