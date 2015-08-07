actionUtil = require 'sails/lib/hooks/blueprints/actionUtil'

module.exports = (req, res, next) ->
	values = actionUtil.parseValues(req)
	domain = sails.config.xmpp.muc
	if values.type == "Members-Only"
		domain = "#{values.createdBy.username}.#{domain}"
	req.options.values.jid = "#{values.name}@#{domain}"
	next()