module.exports = 
	policies:
		UserController:
			'*':		false
			find:		['bearer']
			findOne:	['bearer', 'user/me']
			update:		['bearer', 'user/me', 'isOwner', 'omitId']
		RosterController:
			'*':		false
			find:		['bearer', 'roster/filterByOwner']
			create:		['bearer', 'setOwner', 'roster/setJid']
			update:		['bearer', 'isOwner', 'omitId', 'roster/include']
			destroy:	['bearer', 'isOwner']
		GroupController:
			'*':		false
			find:		['bearer', 'group/publicOnly']
			membersOnly:['bearer']
			findOne:	['bearer']
			create:		['bearer', 'setOwner', 'group/setJid']
			update:		['bearer', 'group/editAllowed', 'omitId']
			destroy:	['bearer', 'isOwner']
		MsgController:
			'*':		false
			'find':		['bearer', 'msg/enterAllowed', 'msg/filterByRoom']
			'create':	['bearer', 'msg/withVoice', 'setOwner', 'msg/setFrom']	