_ = require 'lodash'
actionUtil = require 'sails/lib/hooks/blueprints/actionUtil'

module.exports = 
	# create roster items for sender if not yet defined
	# return promise to resolve a roster item
	sender: (from, to) ->
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
					sails.models.roster
						.findOrCreate(cond, data)
						.populateAll()
				else
					Promise.reject new Error "#{from} or #{to} not found"
		
	# create roster items for recipient(s) if not yet defined		
	# return promise to resolve array of roster items
	recipient: (from, to) ->
		if not sails.services.jid.isMuc(to)
			@sender to, from
				.then (item) ->
					[item]
		else
			sails.models.group
				.findOne jid: to
				.populateAll()
				.then (group) ->
					# default to create roster items for owner and moderators only
					ret = _.uniq [group.createdBy].concat(group.moderators), 'id'
					# also create roster items for members of private group
					if group.isPrivate()
						ret = ret.concat group.members
					return ret
				.then (users) ->
					Promise.all _.map users, (user) ->
						sails.services.roster.sender user.jid, to
		
	# create sender and recipient(s) roster items				
	subscribeAll: (from, to) ->
		Promise
			.all [@sender(from, to), @recipient(from, to)]
			.then (res) ->
				[res[0]].concat res[1]
