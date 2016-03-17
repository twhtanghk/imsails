module.exports =
	# promise to resolve all sockets subscribed to the input roomName
	clients: (roomName) ->
		new Promise (resolve, reject) ->
			sails.io.sockets.in(roomName)
				.clients (err, clients) ->
					if err
						return reject err
					resolve clients
					
	# call underlying broadcast only if clients are not empty array  
	broadcast: (clients, data...) ->
		if _.isArray(clients) and clients.length
			sails.sockets.broadcast.apply undefined, arguments 