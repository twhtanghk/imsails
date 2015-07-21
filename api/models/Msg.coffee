 # Msg.coffee
 #
 # @description :: TODO: You might write a short summary of how this model works and what it represents here.
 # @docs        :: http://sailsjs.org/#!documentation/models

module.exports =

	tableName:	'msgs'
		
	schema:		true
	
	attributes:
		from:				
			type: 		'string'
			required:	true
		to:				
			type: 		'string'
			required: 	true
		type:
			type: 		'string'
			defaultsTo: 'chat'
		body:			
			type: 		'string'
			required:	true
		createdBy:
			model:		'user'
			required:	true
			
	broadcast: (roomName, eventName, data, socketToOmit) ->
		# filter if socket.user is authorized to listen the created msg
		sockets = _.map sails.sockets.subscribers(roomName)
		to = data.data.to
		if sails.services.jid.isMuc to
			sails.models.group
				.findOne jid: to
				.populateAll()
				.then (group) ->
					ret = _.filter sockets, (id) ->
						group?.enterAllowed sails.sockets.get(id).user
					sails.sockets.emit ret, eventName, data
				.catch sails.log.error
		else
			ret = _.filter sockets, (id) ->
				to == sails.sockets.get(id).user.jid
			sails.sockets.emit ret, eventName, data