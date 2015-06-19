module.exports = 
	policies:
		UserController:
			'*':		false
			find:		['bearer', 'online']
			findOne:	['bearer', 'online']
			update:		['bearer', 'online', 'owner']
		RosterController:
			'*':		false
			find:		['bearer', 'online']
			create:		['bearer', 'online']
			update:		['bearer', 'online', 'owner']
			destroy:	['bearer', 'online', 'owner']
		MsgController:
			'*':		false
			'find':		['bearer', 'online']
			'create':	['bearer', 'online']	