module.exports = 
	policies:
		UserController:
			'*':		false
			find:		['bearer']
			findOne:	['bearer', 'user/me']
			update:		['bearer', 'user/me', 'isOwner', 'omitId']
			getPhoto:	true
		RosterController:
			'*':		false
			find:		['bearer', 'roster/filterByOwner']
			create:		['bearer', 'setOwner', 'roster/setJid']
			update:		['bearer', 'isOwner', 'omitId', 'roster/include']
			destroy:	['bearer', 'isOwner']
		GroupController:
			'*':		false
			find:		['bearer', 'group/publicOnly']
			findOne:	['bearer']
			create:		['bearer', 'setOwner', 'group/setJid']
			update:		['bearer', 'group/canEdit', 'omitId']
			destroy:	['bearer', 'group/canRemove']
			membersOnly:['bearer']
			getPhoto:	true
		MsgController:
			'*':		false
			'find':		['bearer', 'msg/canEnter', 'msg/filterByRoom']
			'create':	['bearer', 'msg/canVoice', 'setOwner', 'msg/setFrom']	