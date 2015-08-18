module.exports = 
	policies:
		UserController:
			'*':		false
			find:		['isAuth']
			findOne:	['isAuth', 'user/me']
			update:		['isAuth', 'user/me', 'isOwner', 'omitId', 'user/exclude']
			getPhoto:	true
		RosterController:
			'*':		false
			find:		['isAuth', 'roster/filterByOwner']
			create:		['isAuth', 'setOwner', 'roster/setJid']
			update:		['isAuth', 'isOwner', 'omitId', 'roster/include']
			destroy:	['isAuth', 'isOwner']
		GroupController:
			'*':		false
			find:		['isAuth', 'group/publicOnly']
			findOne:	['isAuth']
			create:		['isAuth', 'setOwner', 'group/setJid']
			update:		['isAuth', 'group/canEdit', 'omitId', 'group/exclude']
			destroy:	['isAuth', 'group/canRemove']
			membersOnly:['isAuth']
			getPhoto:	true
		MsgController:
			'*':		false
			'find':		['isAuth', 'msg/canEnter', 'msg/filterByRoom']
			'create':	['isAuth', 'msg/canVoice', 'setOwner', 'msg/setFrom']	