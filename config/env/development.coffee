path = '/im.app'

module.exports =
	path:			path
	port:			3000
	adminUser:		
		username:	'imadmin'
		email:		'twhtanghk@gmail.com'
	authGrp:		'Authenticated Users'
	promise:
		timeout:	10000 # ms
	oauth2:
		verifyURL:			"https://mob.myvnc.com/org/oauth2/verify/"
		scope:				[ "https://mob.myvnc.com/org/users", "https://mob.myvnc.com/xmpp" ]
	xmpp:
		domain:			'mob.myvnc.com'
		muc:			'muc.mob.myvnc.com'
	models:
		connection: 'mongo'
		migrate:	'alter'
	connections:
		mongo:
			adapter:	'sails-mongo'
			driver:		'mongodb'
			host:		'localhost'
			port:		27017
			user:		'imrw'
			password:	'password'
			database:	'im'
	session:
		adapter:	'mongo'
		host: 		'localhost'
		port: 		27017
		db:			'im'
		username:	'imrw'
		password:	'password'
	sockets:
		path:	"#{path}/socket.io"
	log:
		level:		'silly'