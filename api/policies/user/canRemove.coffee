actionUtil = require 'sails/lib/hooks/blueprints/actionUtil'

module.exports = (req, res, next) ->
	pk = actionUtil.parsePk(req)
	Promise
		.all [
			sails.models.user
				.findOne pk
				.populateAll()
			sails.models.group
				.findOne req.param 'parentid'
				.populateAll()
			]
		.then (res) ->
			[user, group] = res
			me = req.user
			contains = ->
				switch req.options.alias
					when 'members'
						return user.isMember group
					when 'moderators'
						return user.isModerator group
					else
						return false			
			# allowed if current login user can edit the specified group
			# or current login user is member or moderator of the group
			if group and (me.canEdit(group) or contains(group, me))  
				return next()
			res.badRequest "Current login user is not moderator or owner or group #{group.name} not containing #{user.username}" 
		.catch res.serverError