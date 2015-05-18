module.exports =
	path:			'/im'
	port:			3000
	promise:
		timeout:	10000 # ms
	oauth2:
		verifyURL:			"https://mob.myvnc.com/org/oauth2/verify/"
		scope:				[ "https://mob.myvnc.com/org/users", "https://mob.myvnc.com/xmpp" ]
	xmpp:
		domain:		'mob.myvnc.com'
		transports:	['old-websocket']
		wsURL:		"wss://mob.myvnc.com/xmpp-websocket"
		muc:		"muc.mob.myvnc.com"
	models:
		connection: 'mongo'
		migrate:	'alter'
	connections:
		mongo:
			adapter: 	'sails-mongo'
			driver:		'mongodb'
			host:		'localhost'
			port:		27017
			user:		'imrw'
			password:	'password'
			database:	'im'
			socketOptions:
				socketTimeoutMS: 0
	session:
		adapter:	'mongo'
		host: 		'localhost'
		port: 		27017
		db:			'im'
		username:	'imrw'
		password:	'password'
			