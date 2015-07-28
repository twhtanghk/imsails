dump = ->
	_.each sails.io.sockets.sockets, (socket) ->
		rooms =  sails.sockets.socketRooms socket
		sails.log.verbose "#{socket.user?.jid}: #{JSON.stringify(rooms)}" 	
	
module.exports = 
	bootstrap:	(cb) ->
		setInterval dump, 5000
		cb()