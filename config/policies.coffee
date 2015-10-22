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
			update:		['isAuth', 'user/canEdit', 'omitId', 'group/exclude']
			destroy:	['isAuth', 'user/canRemove']
			membersOnly:['isAuth']
			getPhoto:	true
			exit:		['isAuth', 'omitId', 'group/exclude']
		MsgController:
			'*':		false
			'find':		['isAuth', 'user/canEnter', 'roster/findOrCreate', 'msg/filterByRoom']
			'create':	['isAuth', 'user/canVoice', 'setOwner', 'msg/setFrom']
			'putFile':	['isAuth', 'user/canVoice', 'setOwner', 'msg/setFrom']
			'getFile':	['isAuth', 'user/canRead']
			'getThumb':	['isAuth', 'user/canRead']