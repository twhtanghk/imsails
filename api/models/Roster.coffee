 # Roster.coffee
 #
 # @description :: TODO: You might write a short summary of how this model works and what it represents here.
 # @docs        :: http://sailsjs.org/#!documentation/models

module.exports =

	autoWatch:			false
	
	autosubscribe:		['update']
	
	tableName:	'rosters'
	
	schema:		true
	
	attributes:
		jid:
			type: 		'string'
			required:	true
		user:
			model:		'user'
			defaultsTo:	null
		group:
			model:		'group'
			defaultsTo:	null
		type:
			type:		'string'
			defaultsTo:	'chat'			# 'chat' or 'groupchat'
		newmsg:
			type:		'integer'
			defaultsTo:	0
		lastmsgAt:
			type:		'datetime'
			defaultsTo:	new Date(0)
		createdBy:
			model:		'user'
			required:	true
		name: ->
			if sails.services.jid.isMuc(@jid)
				@group?.name
			else
				@user?.fullname()
				
	afterUpdate: (updatedRecord, cb) ->
		@publishUpdate updatedRecord.id, _.omit(updatedRecord, 'user', 'group')
		cb() 
		
	broadcast: (roomName, eventName, data, socketToOmit) ->
		# filter to broadcast data update event to roster owner only 
		sockets = sails.sockets.subscribers(roomName)
		sails.models.roster.findOne(data.id)
			.then (roster) ->
				ret = _.filter sockets, (id) ->
					sails.sockets.get(id).user.id == roster.createdBy
				sails.sockets.emit ret, eventName, data
			.catch sails.log.error