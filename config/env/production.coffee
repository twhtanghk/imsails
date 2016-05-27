uuid = require 'node-uuid'
agent = require 'https-proxy-agent'
winston = require 'winston'

module.exports =
	hookTimeout:	400000
	adminUser:		
		username:	'imadmin'
		email:		'imadmin@mob.myvnc.com'
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
			url:		'mongodb://mongo/im'
	session:
		secret: 	'41bfa8fb25bde0164c3e5b82f45dd27d'
		adapter:	'mongo'
		url:		'mongodb://mongo/im'
	file:
		opts:
			adapter:	require 'skipper-gridfs'
			uri:		'mongodb://mongo/im'
			maxBytes:	10240000	# 10MB
			saveAs:		(stream, next) ->
				# convert input wav stream to ogg stream
				if sails.services.file.type(stream.filename) == 'audio/wave'
					stream = sails.services.audio.mp3(stream)
				next(null, "#{uuid.v4()}/#{stream.filename}")
		img:
			resize:		'25%'
	log:
		level:		'info'
		custom: new winston.Logger
			transports: [
				new winston.transports.Console
					level:		'silly'
					timestamp:	true
			]
