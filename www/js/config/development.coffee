url = 'http://localhost:3000'
path = ''		# context path '/im.app'

io.sails.url = url
io.sails.path = "#{path}/socket.io"
io.sails.useCORSRouteToGetCookie = false
    
module.exports =
	whitelist:
		img:	/^\s*((https?|ftp|file|blob|filesystem):|data:image\/)/ 
		url:	['self', "#{url}/**", 'filesystem:**', 'blob:**']
	server:
		app:
			url:		url					# server url
			urlRoot:	"#{url}#{path}"		# api url
		auth:
			urlRoot:	'https://mob.myvnc.com/org'
		mobile:
			urlRoot:	'https://mob.myvnc.com/mobile'
	isMobile: ->
		/Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent)
	isNative: ->
		/^file/i.test(document.URL)
	platform: ->
		if module.exports.isNative() then 'mobile' else 'browser'
	oauth2: ->
		opts:
			authUrl: 		"#{module.exports.server.auth.urlRoot}/oauth2/authorize/"
			response_type:	"token"
			scope:			"https://mob.myvnc.com/org/users https://mob.myvnc.com/mobile"
			client_id:		if module.exports.isNative() then 'imappDEV' else 'imDEV'
	push:
		gcm:
			senderID:	'sender ID here'
	file:
		target: (file) ->
			switch device.platform
				when 'browser'
					file
				when 'Android'
					cordova.file.externalCacheDirectory + file
		audio:	'audio.wav'