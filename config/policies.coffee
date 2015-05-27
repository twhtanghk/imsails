module.exports = 
	policies:
		UserController:
			'*':		false
			find:		['bearer']
			findOne:	['bearer']
			update:		['bearer', 'owner']
		RosterController:
			'*':		false
			find:		['bearer']
			create:		['bearer']
			update:		['bearer', 'owner']
			destroy:	['bearer', 'owner']
		MsgController:
			'*':		false
			'find':		['bearer']
			'create':	['bearer']	