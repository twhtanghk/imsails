actionUtil = require 'sails/lib/hooks/blueprints/actionUtil'
_ = require 'lodash'
XMPP = require 'stanza.io'
Promise = require 'promise'

Bookmark =

	list: (user) ->
		return new Promise (fulfill, reject) ->
			user.xmpp.getBookmarks (err, res) ->
				if err
					reject new Error err.error.condition 
				else
					fulfill if 'conferences' of res.privateStorage.bookmarks then res.privateStorage.bookmarks.conferences else []
					
	create: (user, data) ->
		# join the room
		user.xmpp.joinRoom data.jid, user.xmpp.jid.local
		return user.xmpp.addBookmark(data)
		
	del: (user, jid) ->
		return new Promise (fulfill, reject) ->
			user.xmpp.removeBookmark jid, (err, res) ->
				if err
					reject new Error err.error.condition 
				else
					fulfill 'deleted successfully'

Room = 

	list: (user) ->
		return new Promise (fulfill, reject) ->
			user.xmpp.getDiscoItems sails.config.xmpp.muc, '', (err, res) ->
				if err
					reject new Error err.error.condition
				else
					results = if 'items' of res.discoItems then res.discoItems.items else []
					fulfill
						count: 		results.length
						results:	results					
					
	create: (user, jid, privateroom) ->
		return new Promise (fulfill, reject) ->
			# join the room to create transient room
			user.xmpp.joinRoom jid, user.xmpp.jid.local
			
			success = (config) ->
				data =
					name: 		(new user.xmpp.JID jid).local
					autoJoin:	true
					jid:		jid
				p1 = Bookmark.create user, data
					
				_.findWhere(config.fields, name: 'muc#roomconfig_persistentroom')?.value = true
				if privateroom
					_.findWhere(config.fields, name: 'muc#roomconfig_membersonly')?.value = true
				config.type = 'submit'
				p2 = Room.update(user, jid, config)
				
				p = Promise.all([p1, p2]).then fulfill, reject 
			
			# read config
			Room.read(user, jid).then success, reject
			
	read: (user, jid) ->
		return new Promise (fulfill, reject) ->
			user.xmpp.getRoomConfig jid, (err, res) ->
				if err
					reject new Error err.error.condition
				else
					fulfill res.mucOwner.form
	
	update: (user, jid, data) ->
		return new Promise (fulfill, reject) ->
			user.xmpp.configureRoom jid, data, (err, res) ->
				if err
					reject new Error err.error.condition
				else
					fulfill res

	del: (user, jid) ->
		return new Promise (fulfill, reject) ->
			success = (config) ->
				_.findWhere(config.fields, name: 'muc#roomconfig_persistentroom')?.value = false
				config.type = 'submit'
				Room.update(user, jid, config).then fulfill, reject
			
			# read config
			Room.read(user, jid).then success, reject
					
Roster =

	create: (user, data) ->
		new Promise (fulfill, reject) ->
			user.xmpp.updateRosterItem data, (err, ret) ->
				user.xmpp.subscribe data.jid 
				if err
					reject new Error err.error.condition
				else
					fulfill ret
	
	update: (user, data) ->
		new Promise (fulfill, reject) ->
			user.xmpp.updateRosterItem data, (err, ret) ->
				if err
					reject new Error err.error.condition
				else
					fulfill res
					
	destroy: (user, jid) ->
		new Promise (fulfill, reject) ->
			user.xmpp.unsubscribe(jid)
			user.xmpp.removeRosterItem jid, (err, ret) ->
				if err
					reject new Error err.error.condition
				else
					fulfill ret

Vcard =
		
	findOne: (user, jid) ->
		new Promise (fulfill, reject) ->
			user.xmpp.getVCard jid, (err, res) ->
				if err
					if err.error?.condition == 'item-not-found'
						fulfill _.extend {}, jid: jid
					else 
						reject new Error err.error.condition
				else 
					fulfill _.extend res.vCardTemp, jid: jid
				
	update: (user, data) ->
		new Promise (fulfill, reject) ->
			user.xmpp.publishVCard data, (err, res) ->
				if err
					reject new Error err.error.condition
				else
					fulfill data
	
module.exports = 
	Bookmark:	Bookmark
	Room:		Room
	Roster:		Roster
	Vcard:		Vcard