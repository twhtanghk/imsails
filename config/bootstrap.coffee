_ = require 'lodash'

dump = ->
	_.each sails.io.sockets.sockets, (socket) ->
		rooms =  sails.sockets.socketRooms socket
		sails.log.verbose "#{socket.user?.jid}: #{JSON.stringify(rooms)}" 	
	
module.exports = 
	bootstrap:	(cb) ->
		# setInterval dump, 5000
		
		sails.models.user
			.findOrCreate username: sails.config.adminUser.username,
				url:		"https://mob.myvnc.com/org/api/users/#{sails.config.adminUser.username}/"
				username:	sails.config.adminUser.username
				email:		sails.config.adminUser.email
				name: 
					given:	'Administrator'
			.then (admUser) ->
				sails.models.group
					.findOrCreate name: sails.config.authGrp,
						jid:		"#{sails.config.authGrp}@#{sails.config.xmpp.muc}"
						name:		sails.config.authGrp
						type:		'Moderated'
						createdBy:	admUser
					.then (admGrp) ->
						cb()
			.catch cb
