actionUtil = require 'sails/lib/hooks/blueprints/actionUtil'

module.exports = 
	findOrCreate: (from, to) ->
		new Promise (fulfill, reject) ->
			targetModel = if sails.services.jid.isMuc(to) then sails.models.group else sails.models.user
			Promise
				.all [
					sails.models.user.findOne jid: from
					targetModel.findOne jid: to
				]
				.then (res) ->
					[_from, _to] = res
					if _from? and _to?
						data =
							jid:	to
							type:	sails.services.jid.type(to)
							createdBy:
								id:	_from.id
						_.extend data, if sails.services.jid.isMuc(to) then group: _to else user: _to
						cond =
							jid:		data.jid
							createdBy:	_from.id
						sails.models.roster.findOrCreate(cond, data).then fulfill, reject
					else
						reject new Error "#{from} or #{to} not found"