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
			defaultsTo:	"img/photo.png"
		online:
			type:		'boolean'
		status:
			type:		'string'
			defaultsTo:	'available'
		createdBy:
			model:		'user'
			
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
			_.extend @toObject(), post: @_post(), fullname: @_fullname() 
			
	beforeCreate: (values, cb) ->
		values.jid = "#{values.username}@#{sails.config.xmpp.domain}"
		cb()