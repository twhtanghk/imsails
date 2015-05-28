fs = require 'fs'
_ = require 'lodash'
path = require 'path'
mongoose = require 'mongoose'
findOrCreate = require 'mongoose-findorcreate'
taggable = require 'mongoose-taggable'
Promise = require 'promise'
uniqueValidator = require 'mongoose-unique-validator'

db = sails.config.connections[sails.config.models.connection]
db.url = "#{db.driver}://#{db.user}:#{db.password}@#{db.host}:#{db.port}/#{db.database}"
	
mongoose.connect db.url, { db: { safe: true }}, (err) ->
  	if err
  		console.log "Mongoose - connection error: #{err}"
  	else console.log "Mongoose - connection OK"

opts = 
	toObject:
		virtuals: true
	toJSON:
		virtuals: true

UserAttrs =
	jid:			{ type: String }
	url:			{ type: String, required: true, index: {unique: true} }
	username:		{ type: String, required: true }
	email:			{ type: String, required: true }
	name:
		given:		{ type: String }
		middle:		{ type: String }
		family:		{ type: String }
	organization:
		name:		{ type: String }
	title:			{ type: String }
	phone:
		[
			type:	{ type: String }
			value:	{ type: String }
		]
	otherEmail:
		[
			type:	{ type: String }
			value:	{ type: String }
		]
	address:		
		[
			type:	{ type: String }
			value:	{ type: String }
		]
	photoUrl:		{ type: String, default: "img/photo.png" }
	createdBy:		{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }
	createdAt:		{ type: Date, default: Date.now }

UserSchema = new mongoose.Schema UserAttrs, opts
	
UserSchema.statics =
	search_fields: ->
		return ['username', 'email']
	ordering_fields: ->
		return ['username', 'email']
	ordering: ->
		return 'username'
	isUser: (oid) ->
		p = @findById(oid).exec()
		p1 = p.then (user) ->
			return user != null
		p1.then null, (err) ->
			return false		

UserSchema.plugin(findOrCreate)
UserSchema.plugin(uniqueValidator)

UserSchema.virtual('fullname').get ->
	if @name.given or @name.middle or @name.family
		"#{@name.given || ''} #{@name.middle || ''} #{@name.family || ''}"
	else
		@email
	
UserSchema.virtual('post').get ->
	if @organization?.name or @title
		"#{@organization?.name || ''}/#{@title || ''}"
	else
		""
		
UserSchema.path('username').set (username) ->
	@jid = "#{username}@#{sails.config.xmpp.domain}" 
	return username

UserSchema.pre 'save', (next) ->
	@createdBy = @ 
	next()	

User = mongoose.model 'User', UserSchema
		
RoomAttrs =
	jid:			{ type: String, required: true, index: {unique: true} }
	name:			{ type: String, required: true, index: {unique: true} }
	privateroom:	{ type: Boolean, default: false }
	createdBy:		{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }
	createdAt:		{ type: Date, default: Date.now }
	updatedBy:		{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }
	updatedAt:		{ type: Date, default: Date.now }

RoomSchema = new mongoose.Schema RoomAttrs, opts
	
RoomSchema.statics =
	search_fields: ->
		return ['jid']
	ordering_fields: ->
		return ['jid']
	ordering: ->
		return 'jid'

RoomSchema.plugin(findOrCreate)
RoomSchema.plugin(taggable)
RoomSchema.plugin(uniqueValidator)

RoomSchema.path('name').set (name) ->
	@jid ?= "#{name}@#{sails.config.xmpp.muc}"
	return name

RoomSchema.pre 'save', (next) ->
	@update $set: updatedAt: Date.now() 
	next()	
				
Room = mongoose.model 'Room', RoomSchema

MsgAttrs =
	from:			{ type: String, required: true }
	to:				{ type: String, required: true }
	type:			{ type: String, default: 'chat' }
	body:			{ type: String }
	createdBy:		{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }
	createdAt:		{ type: Date, default: Date.now }

MsgSchema = new mongoose.Schema MsgAttrs, opts
	
MsgSchema.statics =
	search_fields: ->
		return ['from', 'to', 'type', 'body']
	ordering_fields: ->
		return ['-stamp']
	ordering: ->
		return '-stamp'

MsgSchema.pre 'validate', (next) ->
	@from = "#{@createdBy.username}@#{sails.config.xmpp.domain}"
	next()
	
Msg = mongoose.model 'Msg', MsgSchema
			
RosterAttrs =
	jid:			{ type: String, required: true }
	name:			{ type: String, required: true }
	groups:			{ type: [ String ] }
	createdBy:		{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }
	createdAt:		{ type: Date, default: Date.now }

RosterSchema = new mongoose.Schema RosterAttrs, opts

RosterSchema.index { jid: 1, createdBy: 1 }, { unique: true }	

RosterSchema.statics =
	ordering: ->
		return 'name'

RosterSchema.plugin(uniqueValidator)

Roster = mongoose.model 'Roster', RosterSchema

module.exports = 
	models:
		user: 		User
		roster:		Roster
		room: 		Room
		msg:		Msg