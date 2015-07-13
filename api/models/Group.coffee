 # Group.coffee
 #
 # @description :: TODO: You might write a short summary of how this model works and what it represents here.
 # @docs        :: http://sailsjs.org/#!documentation/models
Promise = require 'promise'

module.exports =

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
		photoUrl:
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
		isOwner: (user) ->
			@createdBy.id == user.id
		isModerator: (user) ->
			_.any @moderators, (item) ->
				item.id == user.id
		isMember: (user) ->
			@type == 'Unmoderated' or _.any @members, (item) ->
				item.id == user.id 
		isVisitor: (user) ->
			@type == 'Moderated'
		enterAllowed: (user) ->
			@isVisitor(user) or @isMember(user) or @isModerator(user) or @isOwner(user)
		withVoice: (user) ->
			@isMember(user) or @isModerator(user) or @isOwner(user)
		editAllowed: (user) ->
			@isModerator(user) or @isOwner(user)
		removeAllowed: (user) ->
			@isOwner(user)
			
	afterCreate: (values, cb) ->
		if values.type != 'Members-Only'
			return cb null, values
		sails.models.group
			.findOne()
			.populateAll()
			.where(id: values.id)
			.then (group) ->
				if not group
					return res.notFound "Group #{values.name} not found"
				users = _.union group.moderators, group.members
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