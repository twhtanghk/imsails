 # Msg.coffee
 #
 # @description :: TODO: You might write a short summary of how this model works and what it represents here.
 # @docs        :: http://sailsjs.org/#!documentation/models
_ = require 'lodash'
Promise = require 'bluebird'
gfs = require('skipper-gridfs')(sails.config.file.opts)
path = require 'path'

module.exports =

	autoWatch:			true

	autosubscribe:		['create']

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
		file:
			type:		'string'
		file_inode:
			model:	'gridfs'
		createdBy:
			model:		'user'
			required:	true
		toJSON: ->
			ret = _.extend @toObject(), mime: @getMime()
			if ret.file
				ret.file = _.extend path.parse(ret.file),
					org: ret.file
					url: "api/msg/file/#{@id}"
				if sails.services.file.isImg(@file_inode) or sails.services.file.isVideo(@file_inode)
					_.extend ret.file, thumbUrl: "api/msg/file/thumb/#{@id}"
			return ret
		getMime: ->
			return if @file then sails.services.file.type(@file_inode) else 'text/html'
		isImg: ->
			return if @file then sails.services.file.isImg(@file_inode) else false
		isAudio: ->
			return if @file then sails.services.file.isAudio(@file_inode) else false

	broadcast: (roomName, eventName, data, socketToOmit) ->
		to = data.data.to
		from = data.data.from

		# read message details and broadcast to those authorized listeners
		broadcast = (sockets) ->
			sails.models.msg
				.findOne data.id
				.populateAll()
				.then (message) ->
					_.extend data, data: message.toJSON()
					sails.services.socket.broadcast sockets, eventName, data

		# filter if socket.user is authorized to listen the created msg
		sails.services.socket
			.clients(roomName)
			.then (clients) ->
				if sails.services.jid.isMuc to
					sails.models.group
						.findOne jid: to
						.populateAll()
						.then (group) ->
							broadcast _.filter clients, (id) ->
								sails.sockets.get(id).user.canEnter group
				else
					broadcast _.filter clients, (id) ->
						to == sails.sockets.get(id).user.jid or from == sails.sockets.get(id).user.jid
			.catch sails.log.error

	beforeCreate: (values, cb) ->
		values.type = sails.services.jid.type values.to
		cb()

	afterCreate: (values, cb) ->
		# find or create roster items for those subscribers for msg.from and msg.to
		sails.services.roster
			.subscribeAll values.from, values.to
			.then ->
				if sails.services.jid.isMuc values.to
					# search for all subscribed rosters
					sails.models.roster
						.find jid: values.to
						.populateAll()
				else
					sails.models.user
						.findOne jid: values.to
						.then (user) ->
							sails.models.roster
								.find
									jid: values.from
									createdBy: user.id
								.populateAll()
			.then (items) ->
				# update all subscribers' roster item
				Promise.map items, (roster) ->
					roster.sent values
			.then ->
				cb()
			.catch cb

	afterDestroy: (values, cb) ->
		_.each values, (msg) ->
			if msg.file
				gfs.rm msg.file, (err) ->
					if err
						sails.log.error err
		cb()

	afterPublishCreate: (values, req) ->
		# send push notification to all subscribers excluding sender
		sails.models.roster
			.findOne jid: values.to
			.populateAll()
			.then (items) ->
				Promise.map items, (item) ->
					if item.createdBy.jid != values.from
						sails.services.gcm
							.push req.user.token, item, values
			.catch sails.log.error
