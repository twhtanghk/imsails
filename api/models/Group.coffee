 # Group.coffee
 #
 # @description :: TODO: You might write a short summary of how this model works and what it represents here.
 # @docs        :: http://sailsjs.org/#!documentation/models
Promise = require 'promise'

module.exports =

	autoWatch:			true
	
	autosubscribe:		['update']
	
	tableName:			'groups'
	
	types:
		type: (name) ->
			_.contains ['Members-Only', 'Unmoderated', 'Moderated'], name
			
		organization: (org) ->
			org.name?
	
	schema:		true
	
	attributes:
		jid:
			type: 		'string'
			required:	true
			unique:		true
		name:
			type: 		'string'
			required:	true
		photo:
			type: 		'string'
		moderators:
			collection:	'user'
			via:		'moderatorGrps'
		members:
			collection:	'user'
			via:		'memberGrps'
		createdBy:
			model:		'user'
		type: 
			type:		'string'
			required:	true
		
		_photoUrl: ->
			return if @photo then "group/photo/#{@id}?m=#{@updatedAt}" else null
			
		# exclude the field photo for data retrieval
		toJSON: ->
			ret = _.extend @toObject(), photoUrl: @_photoUrl()
			delete ret.photo
			return ret
			
		isPublic: ->
			not @isPrivate()
	
		isPrivate: ->
			type == 'Members-Only'
			
	afterCreate: (values, cb) ->
		if values.type != 'Members-Only'
			return cb null, values
		# add this group into roster of the defined members 
		sails.models.group
			.findOne()
			.populateAll()
			.where(id: values.id)
			.then (group) ->
				if not group
					return res.notFound "Group #{values.name} not found"
				users = _.uniq _.union([group.createdBy], group.moderators, group.members), 'id'
				Promise
					.all _.map users, (item) ->
						sails.models.roster.create
							jid:		group.jid
							group:		group
							type:		'groupchat'
							createdBy:	item
					.then (result) ->
						cb null, values
					.catch cb
			.catch cb
		
	afterDestroy: (values, cb) ->
		_.each values, (group) ->
			# remove all roster reference to the deleted group
			sails.models.roster
				.destroy(jid: group.jid)
				.catch sails.log.error
			# remove all msg sent to the deleted group
			sails.models.msg
				.destroy(to: group.jid)
				.catch sails.log.error
		cb()
       			
	beforePublishUpdate: (id, changes, req, options) ->
		# update photoUrl if photo is updated
		if changes.photo
			now = new Date()
			changes.photoUrl = "group/photo/#{id}?m=#{now}"
			delete changes.photo
		
	# return group "Authenticated Users"	
	authGrp: (cb) ->
		ret = sails.models.group
			.findOne name: sails.config.authGrp
			.populateAll()
			
		if cb
			ret.nodeify cb
			return @
		return ret