module.exports =
	sockets:
		onDisconnect: (session, socket) ->
			if socket.user
				values = {online: false, status: ''}
				sails.models.user.update(socket.user.id, values).exec (err, updated) ->
					if updated
						sails.models.user.publishUpdate socket.user, values