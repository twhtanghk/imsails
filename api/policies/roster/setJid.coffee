actionUtil = require 'sails/lib/hooks/blueprints/actionUtil'

module.exports = (req, res, next) ->
	values = actionUtil.parseValues(req)
	req.options.values.jid = if values.type == 'chat' then values.user.jid else values.group.jid
	next()