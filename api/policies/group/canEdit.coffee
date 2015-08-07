actionUtil = require 'sails/lib/hooks/blueprints/actionUtil'

module.exports = (req, res, next) ->
	pk = actionUtil.parsePk(req)
	sails.models.group
		.findOne pk
		.populateAll()
		.then (group) ->
			if group?.editAllowed(req.user) 
				next()
			else
				res.notFound pk
		.catch res.serverError