_ = require 'lodash'

module.exports =
	fullname: (user) ->
		if user.name?.given or user.name?.middle or user.name?.family
			"#{user.name?.given || ''} #{user.name?.middle || ''} #{user.name?.family || ''}".trim()
		else
			user.email.trim()
		
	post: (user) ->
		if user.organization?.name or user.title
			"#{user.organization?.name || ''}/#{user.title || ''}"
		else
			""
		
	isOwner: (user, group) ->
		owner = group?.createdBy.id || group?.createdBy
		owner == user?.id
		
	isModerator: (user, group) ->
		_.any user?.moderatorGrps, (item) ->
			grp = item.id || item
			grp == group?.id
			
	isMember: (user, group) ->
		group?.type == 'Unmoderated' or _.any user?.memberGrps, (item) ->
			grp = item.id || item
			grp == group?.id
			
	isVisitor: (user, group) ->
		group?.type == 'Moderated'

	# check if user is authorized to enter the chatroom
	canEnter: (user, group) ->
		@isVisitor(user, group) or @isMember(user, group) or @isModerator(user, group) or @isOwner(user, group)
		
	# check if user is authorized to send message to the chatroom
	canVoice: (user, group) ->
		@isMember(user, group) or @isModerator(user, group) or @isOwner(user, group)
		
	# check if user is authorized to edit the group settings
	canEdit: (user, group) ->
		@isModerator(user, group) or @isOwner(user, group)
	
	# check if user is authorized to remove this group
	canRemove: (user, group) ->
		@isOwner(user, group)
		
	# check if user is authorized to read the message
	canRead: (user, msg) ->
		new Promise (fulfill, reject) ->
			if sails.services.jid.isMuc(msg.to)
				sails.models.group
					.findOne(jid: msg.to)
					.populateAll()
					.then (group) ->
						if group
							return fulfill(user.canEnter(group))
						sails.log.error "No record found with the specified group #{msg.to}."
						reject(false)
					.catch sails.log.error
			else
				fulfill(user.jid == msg.from or user.jid == msg.to)
