 # Msg.coffee
 #
 # @description :: TODO: You might write a short summary of how this model works and what it represents here.
 # @docs        :: http://sailsjs.org/#!documentation/models
Promise = require 'promise'

module.exports =

	autoWatch:			true
	
	autosubscribe:		false
	
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
			defaultsTo:	'file'
		file:
			type:		'string'
		createdBy:
			model:		'user'
			required:	true
			
	broadcast: (roomName, eventName, data, socketToOmit) ->
		to = data.data.to
		from = data.data.from
		msg = sails.models.msg.findOne(data.id)
		grp = sails.models.group.findOne(jid: to).populateAll()
		emit = (sockets) ->
			msg
				.then (message) ->
					_.extend data, data: message.toJSON()
					sails.sockets.emit sockets, eventName, data
				.catch sails.log.error
		
		# filter if socket.user is authorized to listen the created msg
		sockets = _.map sails.sockets.subscribers(roomName)
		if sails.services.jid.isMuc to
			grp
				.then (group) ->
					ret = _.filter sockets, (id) ->
						sails.sockets.get(id).user.canEnter group
					emit(ret)
				.catch sails.log.error
		else
			ret = _.filter sockets, (id) ->
				to == sails.sockets.get(id)?.user.jid or
				from == sails.sockets.get(id)?.user.jid
			emit(ret)
			
	afterPublishCreate: (values, req) ->
		# update all subscribed parties (jid exists in roster)
		query = null
		if sails.services.jid.isMuc(values.to)
			query = sails.models.roster
				.find()
				.where(jid: values.to)
				.populateAll()
		else
			query = sails.models.roster
				.find()
				.where(jid: values.from)
				.populate('createdBy', where: jid: values.to)
				.populate('user')
				.populate('group')
		query
			.then (roster) ->
				# update roster newmsg counter
				_.each roster, (item) ->
					item.newmsg ?= 0
					item.newmsg = item.newmsg + 1
					item.save()
						.then ->
							# send push notification
							sails.services.rest
								.push req.user.token, item, values
								.then sails.log.verbose
								.catch sails.log.error
						.catch sails.log.error
			.catch sails.log.error