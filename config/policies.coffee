module.exports = 
	policies:
		UsersController:
			'*':	'bearer'
		VcardController:
			'*':	['bearer', 'xmpp']
		RosterController:
			'*':	['bearer', 'xmpp']
			'update':	['bearer', 'xmpp', 'owner']
			'destroy':	['bearer', 'xmpp', 'owner']