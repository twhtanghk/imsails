_ = require 'underscore'
Promise = require 'promise'

module.exports =
	find: (req, res) ->
		reject = (err) ->
			res.json 501, err
			
		sails.models.users.find(req.query)
			.then (users) ->
				p = Promise.all _.map users, (user) ->
					XmppService.VCard.read req.user, "#{user.username}@#{sails.config.xmpp.domain}"
				p
					.then (vcards) ->
						res.json vcards
					.catch reject 
			.catch reject