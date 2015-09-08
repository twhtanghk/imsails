 # Group.coffee
 #
 # @description :: TODO: You might write a short summary of how this model works and what it represents here.
 # @docs        :: http://sailsjs.org/#!documentation/models
Promise = require 'promise'

module.exports =

	autoWatch:			true
	
	autosubscribe:		['update']
	
	tableName:	'groups'
	
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
			return if @photo then "#{sails.config.url}/group/photo/#{@id}?m=#{@updatedAt}" else null
			
		# exclude the field photo for data retrieval
		toJSON: ->
			ret = _.extend @toObject(), photoUrl: @_photoUrl()
			delete ret.photo
			return ret
	
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
				users = _.uniq _.union(group.moderators, group.members), 'id'
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
		
	beforePublishUpdate: (id, changes, req, options) ->
		# update photoUrl if photo is updated
		if changes.photo
			now = new Date()
			changes.photoUrl = "#{sails.config.url}/group/photo/#{id}?m=#{now}"
			delete changes.photo
		
	# return group "Authenticated Users"	
	authGrp: (opts, cb) ->
		group = (admin) ->
			jid:			"#{sails.config.authGrp}@#{sails.config.xmpp.muc}"
			name:			sails.config.authGrp
			type:			'Moderated'
			createdBy:		admin
			
		sails.models.user.admin null, (err, admin) ->
			sails.models.group
				.findOrCreate name: sails.config.authGrp, group(admin)
				.populateAll()
				.then (group) ->
					cb null, group
				.catch (err) ->
					sails.log.error err
					cb err