 # Roster.coffee
 #
 # @description :: TODO: You might write a short summary of how this model works and what it represents here.
 # @docs        :: http://sailsjs.org/#!documentation/models
_ = require 'lodash'

module.exports =

	autoWatch:			true
	
	autosubscribe:		['create', 'update']
	
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
		sent: (msg) ->
			switch @jid
				when msg.from
					@lastmsgAt = msg.createdAt
					@newmsg = @newmsg + 1
					@save()
				when msg.to
					@lastmsgAt = msg.createdAt
					# also update msg counter for groupchat members other than roster owner
					if sails.services.jid.isMuc(msg.to) and @createdBy.id != msg.createdBy 
						@newmsg = @newmsg + 1
					@save()
				else
					@
			
	beforeCreate: (values, cb) ->
		values.type = sails.services.jid.type values.jid
		cb()
		
	afterCreate: (createdRecord, cb) ->
		@publishCreate createdRecord
		cb() 
		
	afterUpdate: (updatedRecord, cb) ->
		@publishUpdate updatedRecord.id, updatedRecord
		cb() 
		
	broadcast: (roomName, eventName, data, socketToOmit) ->
		# filter to broadcast data event to roster owner only 
		@findOne data.id
			.populateAll()
			.then (roster) ->
				sails.services.socket.clients roomName
					.then (clients) ->
						clients = _.filter clients, (client) ->
							sails.sockets.get(client).user.id == roster.createdBy.id
						if roster
							data.data = roster
						sails.services.socket.broadcast clients, eventName, data
			.catch sails.log.error
