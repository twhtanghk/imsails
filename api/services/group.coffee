module.exports =
	isOwner: (group, user) ->
		group.createdBy.id == user?.id
		
	isModerator: (group, user) ->
		_.any group.moderators, (item) ->
			item.id == user?.id
			
	isMember: (group, user) ->
		group.type == 'Unmoderated' or _.any group.members, (item) ->
			item.id == user?.id
			
	isVisitor: (group, user) ->
		group.type == 'Moderated'

	# check if user is authorized to enter the chatroom
	canEnter: (group, user) ->
		@isVisitor(group, user) or @isMember(group, user) or @isModerator(group, user) or @isOwner(group, user)
		
	# check if user is authorized to send message to the chatroom
	canVoice: (group, user) ->
		@isMember(group, user) or @isModerator(group, user) or @isOwner(group, user)
		
	# check if user is authorized to edit the group settings
	canEdit: (group, user) ->
		@isModerator(group, user) or @isOwner(group, user)
	
	# check if user is authorized to remove this group
	canRemove: (group, user) ->
		@isOwner(group, user)