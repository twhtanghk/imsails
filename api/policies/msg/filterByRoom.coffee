_ = require 'lodash'
actionUtil = require 'sails/lib/hooks/blueprints/actionUtil'

# add criteria for room jid and current login user  
module.exports = (req, res, next) ->
	values = actionUtil.parseValues(req)
	type = values.type
	to = values.to
	from = req.user.jid
	cond = 
		chat:
			or: [
				{
					to:		to
					from:	from
				}
				{
					to:		from
					from:	to
				}
			]
		groupchat:
			to: to 

	req.options.criteria = req.options.criteria || {}
	req.options.criteria.blacklist = req.options.criteria.blacklist || ['limit', 'skip', 'sort', 'populate', 'to']
	req.options.where = req.options.where || {}
	_.extend req.options.where, cond[type]		
	next()
