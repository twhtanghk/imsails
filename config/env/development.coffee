module.exports =
	promise:
		timeout:	10000 # ms
	oauth2:
		verifyURL:			"https://mob.myvnc.com/org/oauth2/verify/"
		scope:				[ "https://mob.myvnc.com/org/users", "https://mob.myvnc.com/xmpp" ]
	models:
		connection: 'mongo'
		migrate:	'alter'
	connections:
		mongo:
			adapter: 'sails-mongo'
			host: 'localhost'
			port: 27017
			user: 'imrw'
			password: 'pass1234'
			database: 'im'