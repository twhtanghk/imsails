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
	
UserSchema = new mongoose.Schema
	_id:			{ type: String }
	url:			{ type: String, required: true, index: {unique: true} }
	username:		{ type: String, required: true }
	email:			{ type: String }
	createdAt:		{ type: Date, default: Date.now }
	
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

UserSchema.path('url').set (url) ->
	@_id ?= url
	return url

User = mongoose.model 'User', UserSchema

data = (name, persistent = true) ->
	fields:	[ 
		{
			type:	"hidden"
			name:	"FORM_TYPE"
			value:	[ "http://jabber.org/protocol/muc#roomconfig" ]
		},
		{
			type:	"text-single"
			name:	"muc#roomconfig_roomname"
			value:	name
		},
		{
			type:	"text-single"
			name:	"muc#roomconfig_roomdesc"
			value:	""
		},
		{
			type:	"boolean"
			name:	"muc#roomconfig_persistentroom"
			value:	persistent
		},
		{
			type:	"boolean"
			name:	"muc#roomconfig_publicroom"
			value:	true
		},
		{
			type:	"boolean"
			name:	"muc#roomconfig_changesubject"
			value:	true
		},
		{
			type:	"list-single"
			name:	"muc#roomconfig_whois"
			value:	"moderators"
		},
		{
			type:	"text-private"
			name:	"muc#roomconfig_roomsecret"
			value:	""
		},
		{
			type:	"boolean"
			name:	"muc#roomconfig_moderatedroom"
			value:	true
		},
		{
			type:	"boolean"
			name:	"muc#roomconfig_membersonly"
			value:	false
		},
		{
			type:	"text-single"
			name:	"muc#roomconfig_historylength"
			value:	"20"
		}
	]
	type:			'submit'
		
config = (client, roomJid, data, func) ->
	client.configureRoom roomJid, data, (err, res) =>
		func(err, res)
				
RoomSchema = new mongoose.Schema
	_id:			{ type: String }
	jid:			{ type: String, required: true, index: {unique: true} }
	name:			{ type: String, required: true, index: {unique: true} }
	privateroom:	{ type: Boolean, default: false }
	createdBy:		{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }
	createdAt:		{ type: Date, default: Date.now }
	updatedBy:		{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }
	updatedAt:		{ type: Date, default: Date.now }
	
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
RoomSchema.path('jid').set (jid) ->
	@_id ?= jid
	return jid

RoomSchema.path('name').set (name) ->
	@jid ?= "#{name}@#{sails.config.xmpp.muc}"
	return name

RoomSchema.pre 'save', (next) ->
	@wasNew = @isNew
	@update $set: updatedAt: Date.now() 
	if @wasNew
		XmppService.Room.create(@user, @jid, @privateroom).then next, next
	else
		room =
			fields:	@fields
			type:	'submit'
		XmppService.Room.update(@user, @jid, room).then next, next	
				
RoomSchema.pre 'remove', (next) ->
	XmppService.Room.del(@user, @jid).then next, next

Room = mongoose.model 'Room', RoomSchema

BookmarkSchema = new mongoose.Schema
	jid:			{ type: String, required: true }
	name:			{ type: String, required: true }
	autoJoin:		{ type: Boolean, default: true }
	createdBy:		{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }
	createdAt:		{ type: Date, default: Date.now }
	
BookmarkSchema.statics =
	search_fields: ->
		return ['jid']
	ordering_fields: ->
		return ['jid']
	ordering: ->
		return 'jid'

BookmarkSchema.plugin(findOrCreate)
BookmarkSchema.plugin(taggable)

BookmarkSchema.path('name').set (name) ->
	@jid ?= "#{name}@#{sails.config.xmpp.muc}"
	return name

BookmarkSchema.path('autoJoin').set (autoJoin) ->
	xmpp @owner, (client) =>
		if @autoJoin != autoJoin
			if autoJoin 
				client.addBookmark
					jid: 		@jid
					name:		@name
					autoJoin: 	true
			else
				client.removeBookmark @jid
	return autoJoin
			
BookmarkSchema.path('createdBy').set (createdBy) ->
	@owner =
		username: 	createdBy.username
		token:		createdBy.token
	return createdBy
	
BookmarkSchema.pre 'save', (next) ->
	xmpp @owner, (client) ->
		if autoJoin 
			client.addBookmark
				jid: 		@jid
				name:		@name
				autoJoin: 	true
		else
			client.removeBookmark @jid
		client.disconnect()
		next()
		
BookmarkSchema.pre 'remove', (next) ->
	xmpp @owner, (client) =>
		client.removeBookmark @jid
		next()
		
Bookmark = mongoose.model 'Bookmark', BookmarkSchema

MsgSchema = new mongoose.Schema
	msgid:			{ type: String }
	from:			{ type: String, required: true }
	to:				{ type: String, required: true }
	type:			{ type: String, default: 'chat' }
	body:			{ type: String }
	status:			{ type: [ Number ] }
	stamp:			{ type: Date, default: Date.now }
	
MsgSchema.statics =
	search_fields: ->
		return ['from', 'to', 'type', 'body']
	ordering_fields: ->
		return ['-stamp']
	ordering: ->
		return '-stamp'

MsgSchema.plugin(findOrCreate)

MsgSchema.pre 'validate', (next) ->
	if @user
		@from = "#{@user.username}@#{sails.config.xmpp.domain}"
	next()
	
MsgSchema.pre 'save', (next) ->
	if @user.xmpp
		@user.xmpp.sendMessage _.pick(@toJSON(), 'to', 'type', 'body')
	next()
	
Msg = mongoose.model 'Msg', MsgSchema

RosterSchema = new mongoose.Schema
	_id:			{ type: String }
	jid:			{ type: String, required: true }
	name:			{ type: String, required: true }
	groups:			{ type: [ String ] }
	createdBy:		{ type: String, ref: 'User' }
	createdAt:		{ type: Date, default: Date.now }

RosterSchema.index { jid: 1, createdBy: 1 }, { unique: true }	

RosterSchema.statics =
	ordering: ->
		return 'name'

RosterSchema.plugin(findOrCreate)
RosterSchema.plugin(uniqueValidator)

RosterSchema.path('jid').set (jid) ->
	@_id ?= jid
	return jid

RosterSchema.pre 'save', (next) ->
	if @isNew
		XmppService.Roster.create(@createdBy, @toJSON()).then next, next
	else 
		XmppService.Roster.update(@createdBy, @jid, @toJSON()).then next, next
	
RosterSchema.pre 'remove', (next) ->
	XmppService.Roster.delete(@user, @jid).then next, next
	
Roster = mongoose.model 'Roster', RosterSchema

module.exports = 
	models:
		user: 		User
		roster:		Roster
		room: 		Room
		bookmark:	Bookmark
		msg:		Msg