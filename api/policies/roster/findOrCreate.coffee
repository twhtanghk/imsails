actionUtil = require 'sails/lib/hooks/blueprints/actionUtil'

module.exports = (req, res, next) ->
	values = actionUtil.parseValues(req)
	jid = values.to
	targetModel = if sails.services.jid.isMuc(values.to) then sails.models.group else sails.models.user
	targetModel
			.findOne(jid: jid)
			.then (target) ->
				if !target
					return res.serverError "#{jid} not found"
				data =
					jid:	jid
					type:	sails.services.jid.type(values.to)
					createdBy:
						id:	req.user.id
				if sails.services.jid.isMuc(values.to)
					_.extend data, group: target
				else
					_.extend data, user: target
				cond =
					jid: 		data.jid
					createdBy:	req.user.id
				sails.services.crud
					._findOrCreate(req, sails.models.roster, cond, data)
					.then (item) ->
						next()
					.catch res.serverError
			.catch res.serverError