module.exports =
	sockets:
		afterDisconnect: (session, socket, cb) ->
			if socket.user
				values = {online: false, status: ''}
				sails.models.user.update(socket.user.id, values).exec (err, updated) ->
					if updated
						sails.models.user.publishUpdate socket.user.id, values
			cb()