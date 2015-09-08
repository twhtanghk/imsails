actionUtil = require 'sails/lib/hooks/blueprints/actionUtil'

module.exports = (req, res, next) ->
	pk = actionUtil.parsePk(req)
	sails.models.group
		.findOne pk
		.populateAll()
		.then (group) ->
			if group and req.user.canEdit(group) 
				return next()
			res.notFound pk
		.catch res.serverError