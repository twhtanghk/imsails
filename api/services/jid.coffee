module.exports =
	type: (jid) ->
		return if jid.indexOf(sails.config.xmpp.muc) != -1 then 'groupchat' else 'chat'
		
	isMuc: (jid) ->
		@type(jid) == 'groupchat'