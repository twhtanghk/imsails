module.exports =
	type: (jid) ->
		return if /.*@muc.*/.test jid then 'groupchat' else 'chat'
		
	isMuc: (jid) ->
		@type(jid) == 'groupchat'
