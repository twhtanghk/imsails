path = '/im.app'
uuid = require 'node-uuid'

module.exports =
	path:			path
	url:			"http://localhost:3000#{path}"
	port:			3000
	adminUser:		
		username:	'imadmin'
		email:		'twhtanghk@gmail.com'
	authGrp:		'Authenticated Users'
	promise:
		timeout:	10000 # ms
	push:
		url:		"https://mob.myvnc.com/mobile/api/push"
		data:
			url:		"/roster/list"
			title:		"<%=roster.name()%>"
			message:	"<%=roster.newmsg%> new message(s)"	
	oauth2:
		verifyURL:			"https://mob.myvnc.com/org/oauth2/verify/"
		scope:				[ "https://mob.myvnc.com/org/users", "https://mob.myvnc.com/mobile"]
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
	file:
		opts:
			adapter:	require 'skipper-gridfs'
			host:		'localhost'
			port:		27017
			dbname:		'im'
			username:	'imrw'
			password:	'password'
			maxBytes:	10240000	# 10MB
			saveAs:		(stream, next) ->
				next(null, "#{uuid.v4()}/#{stream.filename}")
	sockets:
		path:	"#{path}/socket.io"
	log:
		level:		'silly'