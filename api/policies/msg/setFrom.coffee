actionUtil = require 'sails/lib/hooks/blueprints/actionUtil'

module.exports = (req, res, next) ->
	values = actionUtil.parseValues(req)
	req.options.values.from = values.createdBy.jid
	next()