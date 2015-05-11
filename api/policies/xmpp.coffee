Promise = require 'promise'
XMPP = require 'stanza.io'
shortid = require('shortid')

xmppclient = (user, token) ->
	return new Promise (fulfill, reject) ->
		opts = sails.config.xmpp
		opts.jid = "#{user.username}@#{sails.config.xmpp.domain}"
		opts.password = token
		opts.resource = shortid.generate()
		user.xmpp = client = XMPP.createClient opts
		
		client.on '*', ->
			sails.log.debug arguments
		
		client.on 'session:started', ->
			# keep alive connection
			client.enableKeepAlive interval: 60
			
			# get user bookmarks and join all bookmark room
			success = (bks) ->
				_.each bks, (bk) ->
					if bk.autoJoin
						client.joinRoom bk.jid.bare, user.username
			XmppService.Bookmark.list(user).then success, reject

			# set online status
			client.sendPresence(type: 'available')
						
			fulfill(client)
						
		client.connect()
		
module.exports = (req, res, next) ->
	reject = (err) ->
		res.json 501, err
	fulfill = (client) ->
		next()
	xmppclient(req.user, req.user.token).then fulfill, reject