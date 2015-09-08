 # User.coffee
 #
 # @description :: TODO: You might write a short summary of how this model works and what it represents here.
 # @docs        :: http://sailsjs.org/#!documentation/models

_ = require 'lodash'

pair = (array) ->
	ret = true
	_.each array, (item) ->
		ret = ret && item.type? && item.value?
	return ret
		
fullname = (user) ->
	if user.name?.given or user.name?.middle or user.name?.family
		"#{user.name?.given || ''} #{user.name?.middle || ''} #{user.name?.family || ''}"
	else
		user.email
		
post = (user) ->
	if user.organization?.name or user.title
		"#{user.organization?.name || ''}/#{user.title || ''}"
	else
		""
		
photoUrl = (user) ->
	return if user.photo then "#{sails.config.url}/user/photo/#{user.id}?m=#{user.updatedAt}" else null
	
module.exports =
	
	autoWatch:			false
	
	autosubscribe:		['update']
	
	tableName:	'users'
	
	types:
		name: (name) ->
			name.given? && name.middle? && name.family?
			
		organization: (org) ->
			org.name?

		phone: pair
		
		otherEmail: pair
		
		address: pair
			
	schema:		true
	
	attributes:
		jid:
			type: 		'string'
			required:	true
			unique:		true
		url:
			type: 		'string'
			required: 	true
		username:
			type: 		'string'
			required: 	true
		email:
			type:		'string' 
			required:	true
		name:
			type:		'json'
		fullname:
			type:		'string'
		organization:
			type:		'json'
		title:
			type:		'string'
		phone:
			type:		'array'
		otherEmail:
			type:		'array'
		address:		
			type:		'array'
		photo:
			type: 		'string'
		online:
			type:		'boolean'
		status:
			type:		'string'
			
		# relationship
		ownerGrps:
			collection:	'group'
			via:		'createdBy'
		moderatorGrps:
			collection:	'group'
			via:		'moderators'
		memberGrps:
			collection:	'group'
			via:		'members'
			
		# right of visitor group is NA for Members-Only group 
		# so that visitor group is not considered here
		membersOnlyGrps: ->
			membersOnly = _.union(
				_.where(@ownerGrps, type: 'Members-Only'),
				_.where(@moderatorGrps, type: 'Members-Only'),
				_.where(@memberGrps, type: 'Members-Only')
			)
			membersOnly = _.sortBy membersOnly, 'name'
			_.uniq membersOnly, 'id'
			
		post: ->
			post(@)
			
		photoUrl: ->
			photoUrl(@)
		
		isOwner: (group) ->
			sails.services.user.isOwner(@, group)
			
		isModerator: (group) ->
			sails.services.user.isModerator(@, group)
				
		isMember: (group) ->
			sails.services.user.isMember(@, group)
			
		isVisitor: (group) ->
			sails.services.user.isVisitor(@, group)

		# check if user is authorized to enter the specified group
		canEnter: (group) ->
			sails.services.user.canEnter(@, group)
			
		# check if user is authorized to send message to the specified group
		canVoice: (group) ->
			sails.services.user.canVoice(@, group)
			
		# check if user is authorized to edit the specified group
		canEdit: (group) ->
			sails.services.user.canEdit(@, group)
		
		# check if user is authorized to remove the specified group
		canRemove: (group) ->
			sails.services.user.canRemove(@, group)
			
		# check if user is authorized to read the specified message
		canRead: (msg) ->
			sails.services.user.canRead(@, msg)
				
		toJSON: ->
			@phone = @phone || []
			@otherEmail = @otherEmail || []
			@address = @address || []
			ret = _.extend @toObject(), post: @post(), photoUrl: @photoUrl()
			delete ret.photo
			return ret
			
	beforeValidate: (values, cb) ->
		if values.username
			values.jid = "#{values.username}@#{sails.config.xmpp.domain}"
		if values.name
			values.fullname = fullname(values)
		cb(null, values)
		
	afterCreate: (values, cb) ->
		# add created user into "Authenticated Users" group except administrator
		if values.username == sails.config.adminUser.username
			return cb null, values
			
		sails.models.group.authGrp null, (err, group) ->
			if err
				return cb err
			if group
				group.members.add values
				group.save()
					.then ->
						cb null, values
					.catch (err) ->
						sails.log.error err
						cb err
			else
				cb "#{sails.config.authGrp} not defined"
	
	beforePublishUpdate: (id, changes, req, options) ->
		# update photoUrl if photo is updated
		if changes.photo
			now = new Date()
			_.extend changes, photoUrl: "#{sails.config.url}/user/photo/#{id}?m=#{now}"
			delete changes.photo
		_.extend changes, post: post(changes)
	
	broadcast: (roomName, eventName, data, socketToOmit) ->
		# ignore socketToOmit to broadcast the event to sender also
		sails.sockets.broadcast roomName, eventName, data
		 
	# return administrator		
	admin: (opts, cb) ->
		user = 
			url:		"https://mob.myvnc.com/org/api/users/#{sails.config.adminUser.username}/"
			username:	sails.config.adminUser.username
			email:		sails.config.adminUser.email
			name: 
				given:	'Administrator'
		sails.models.user
			.findOrCreate username: sails.config.adminUser.username, user 
			.then (admin) ->
				cb null, admin
			.catch (err) ->
				sails.log.error err
				cb err