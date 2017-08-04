module.exports = 
	policies:
		UserController:
			'*':		false
			create:		['isAdmin']
			find:		['isAuth']
			findOne:	['isAuth', 'user/me']
			profile:	true
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
			findByMe:	['isAuth', 'filterByOwner']
			findOneByName:	['isAuth', 'filterByOwner']
			membersOnly:['isAuth']
			getPhoto:	true
			create:		['isAuth', 'setOwner', 'group/setJid']
			add:		['isAuth', 'user/me', 'user/canAdd']
			update:		['isAuth', 'user/canEdit', 'omitId', 'group/exclude']
			destroy:	['isAuth', 'user/canDestroy']
			remove:		['isAuth', 'user/me', 'user/canRemove']
			exit:		['isAuth', 'omitId', 'group/exclude']
		MsgController:
			'*':		false
			'find':		['isAuth', 'user/canEnter', 'roster/findOrCreate', 'msg/filterByRoom']
			'create':	['isAuth', 'user/canVoice', 'setOwner', 'msg/setFrom']
			'putFile':	['isAuth', 'user/canVoice', 'setOwner', 'msg/setFrom']
			'getFile':	['isAuthUrl', 'user/canRead']
			'getThumb':	['isAuthUrl', 'user/canRead']
