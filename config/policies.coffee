module.exports = 
	policies:
		UserController:
			'*':		false
			find:		['bearer', 'online']
			findOne:	['bearer', 'online', 'user/me']
			update:		['bearer', 'online', 'user/me', 'isOwner', 'omitId']
		RosterController:
			'*':		false
			find:		['bearer', 'online', 'roster/filterByOwner']
			create:		['bearer', 'online', 'setOwner', 'roster/setJid']
			update:		['bearer', 'online', 'isOwner', 'omitId']
			destroy:	['bearer', 'online', 'isOwner']
		GroupController:
			'*':		false
			find:		['bearer', 'online', 'group/publicOnly']
			membersOnly:['bearer', 'online']
			findOne:	['bearer', 'online']
			create:		['bearer', 'online', 'setOwner', 'group/setJid']
			update:		['bearer', 'online', 'group/editAllowed', 'omitId']
			destroy:	['bearer', 'online', 'isOwner']
		MsgController:
			'*':		false
			'find':		['bearer', 'online', 'msg/enterAllowed', 'msg/filterByRoom']
			'create':	['bearer', 'online', 'msg/withVoice', 'setOwner', 'msg/setFrom']	