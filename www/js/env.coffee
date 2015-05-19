module.exports =
	path: '/im'		
	server:
		app:
			type:	'io'
			url:	''
		auth:
			url:	'https://mob.myvnc.com/org'
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
			scope:			"https://mob.myvnc.com/org/users https://mob.myvnc.com/xmpp"
			client_id:		if @isNative() then 'imappPRD' else 'imDEV'