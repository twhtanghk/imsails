module.exports =
	sockets:
		onDisconnect: (session, socket) ->
			if session.user
				values = {online: false, status: ''}
				sails.models.user.update(session.user, values).exec (err, updated) ->
					if updated
						sails.models.user.publishUpdate session.user, values