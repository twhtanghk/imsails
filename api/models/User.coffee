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
			
module.exports =
	
	autoWatch:			false
	
	autoSubscribe:		true
	
	autoSubscribeDeep:	false
	
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
		photoUrl:
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
				
		_fullname: ->
			if @name?.given or @name?.middle or @name?.family
				"#{@name?.given || ''} #{@name?.middle || ''} #{@name?.family || ''}"
			else
				@email
				
		_post: ->
			if @organization?.name or @title
				"#{@organization?.name || ''}/#{@title || ''}"
			else
				""
				
		toJSON: ->
			@phone = @phone || []
			@otherEmail = @otherEmail || []
			@address = @address || []
			ret = _.extend @toObject(), post: @_post(), fullname: @_fullname()
			if ret.photoUrl
				ret.photoUrl = "#{sails.config.url}/user/photo/#{ret.id}"
			return ret
			
	beforeValidate: (values, cb) ->
		if values.username
			values.jid = "#{values.username}@#{sails.config.xmpp.domain}"
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