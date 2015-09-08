actionUtil = require 'sails/lib/hooks/blueprints/actionUtil'

# check if authenticated user is allowed to read the message with specified id  
module.exports = (req, res, next) ->
	pk = actionUtil.parsePk(req)
	sails.models.msg
		.findOne(pk)
		.populateAll()
		.then (msg) ->
			if msg
				req.user.canRead(msg)
					.then (allowed) ->
						if allowed
							return next()
						res.serverError("Not authorized to read the message")
					.catch res.serverError
			else
				res.notFound()
		.catch res.serverError