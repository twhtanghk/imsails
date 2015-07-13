_ = require 'lodash'
actionUtil = require 'sails/lib/hooks/blueprints/actionUtil'

# default to add owner into moderators
module.exports = (req, res, next) ->
	values = actionUtil.parseValues(req)
	if _.isUndefined _.findWhere(values.moderators, id: values.createdBy.id)
		req.options.values.moderators = if values.moderators then values.moderators.slice() else []
		req.options.values.moderators.push id: values.createdBy.id
	next()