module.exports =
	path: '/im.app'		
	server:
		app:
			type:		'io'						# for model to interface with server (io or rest)
			url:		''							# for model urlRoot
			urlRoot:	'https://mob.myvnc.com:443'		# for socket.io to establish connection
		auth:
			url:	'https://mob.myvnc.com/org'
		mobile:
			url:	'https://mob.myvnc.com/mobile'
	isMobile: ->
		/Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent)
	isNative: ->
		/^file/i.test(document.URL)
	platform: ->
		if @isNative() then 'mobile' else 'browser'
	oauth2: ->
		authUrl: "#{@server.auth.url}/oauth2/authorize/"
		opts:
			response_type:	"token"
			scope:			"https://mob.myvnc.com/org/users https://mob.myvnc.com/xmpp https://mob.myvnc.com/mobile"
			client_id:		if @isNative() then 'imappPRD' else 'imPRD'
	push:
		gcm:
			senderID:	'1027958128694'