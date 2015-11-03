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
			url:		"/chat/<%=roster.type%>/<%=roster.user ? roster.user.id : roster.group.id%>"
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
		secret: 	'41bfa8fb25bde0164c3e5b82f45dd27d'
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
				# convert input wav stream to ogg stream
				if sails.services.file.type(stream.filename) == 'audio/wave'
					stream = sails.services.audio.mp3(stream)
				next(null, "#{uuid.v4()}/#{stream.filename}")
		img:
			resize:		'25%'
	sockets:
		path:	"#{path}/socket.io"
	csp:
		"Content-Security-Policy": "default-src 'self' data:; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; connect-src 'self' ws://localhost:3000; child-src 'self' https://mob.myvnc.com https://*.google.com; object-src 'none'; media-src 'self' data:; img-src 'self' data:"
	log:
		level:		'silly'