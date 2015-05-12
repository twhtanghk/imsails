module.exports = 
	policies:
		UsersController:
			'*':	'bearer'
		RosterController:
			'*':	['bearer', 'xmpp']
		VcardController:
			'*':	['bearer', 'xmpp']