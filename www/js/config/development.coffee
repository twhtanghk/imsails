url = 'http://localhost:3000'
path = 'im.app'

module.exports =
	path: "/#{path}"		
	server:
		app:
			type:		'io'				# api type (io or rest)
			url:		url					# server url
			urlRoot:	"#{url}/#{path}"	# api url
		auth:
			urlRoot:	'https://mob.myvnc.com/org'
		mobile:
			urlRoot:	'https://mob.myvnc.com/mobile'
	isMobile: ->
		/Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent)
	isNative: ->
		/^file/i.test(document.URL)
	platform: ->
		if @isNative() then 'mobile' else 'browser'
	oauth2: ->
		authUrl: "#{@server.auth.urlRoot}/oauth2/authorize/"
		opts:
			response_type:	"token"
			scope:			"https://mob.myvnc.com/org/users https://mob.myvnc.com/xmpp https://mob.myvnc.com/mobile"
			client_id:		if @isNative() then 'imappDEV' else 'imDEV'
	push:
		gcm:
			senderID:	'1027958128694'
	file:
		target: (file) ->
			switch device.platform
				when 'browser'
					file
				when 'Android'
					cordova.file.externalCacheDirectory + file