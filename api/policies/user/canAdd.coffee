actionUtil = require 'sails/lib/hooks/blueprints/actionUtil'

module.exports = (req, res, next) ->
	pk = req.param 'parentid'
	sails.models.group
		.findOne pk
		.populateAll()
		.then (group) ->
			if group and req.user.canEdit(group) 
				return next()	
			res.notFound "Group with id #{pk}"
		.catch res.serverError