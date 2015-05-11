_ = require 'underscore'
XMPP = require 'stanza.io'
logger = sails.log
Promise = require 'promise'

Bookmark =

	list: (user) ->
		return new Promise (fulfill, reject) ->
			user.xmpp.getBookmarks (err, res) ->
				if err
					reject err 
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
					reject err 
				else
					fulfill 'deleted successfully'

Room = 

	list: (user) ->
		return new Promise (fulfill, reject) ->
			user.xmpp.getDiscoItems sails.config.xmpp.muc, '', (err, res) ->
				if err
					reject err
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
					reject err
				else
					fulfill res.mucOwner.form
	
	update: (user, jid, data) ->
		return new Promise (fulfill, reject) ->
			user.xmpp.configureRoom jid, data, (err, res) ->
				if err
					reject err
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

	list: (user) ->
		return new Promise (fulfill, reject) ->
			user.xmpp.getRoster (err, res) ->
				if err
					reject(err)
				else
					###					
					In XMPP standard, if the requested roster version is same as the xmpp server version. 
					The roster object will not be returned. Thus, the current roster is saved in variables
					to ensure that the roster object always exist and return even there is no object return 
					from xmpp server
					###
					 
					if res.roster
						user.xmpp.roster = res.roster
					fulfill(if 'items' of user.xmpp.roster then user.xmpp.roster.items else [])

	create: (user, data) ->
		return new Promise (fulfill, reject) ->
			user.xmpp.updateRosterItem data, (err, res) ->
				user.xmpp.subscribe data.jid
				if err
					reject err
				else
					fulfill res
	
	update: (user, jid, data) ->
		return new Promise (fulfill, reject) ->
			user.xmpp.updateRosterItem data, (err, res) ->
				if err
					reject err
				else
					fulfill res
					
	delete: (user, jid) ->
		return new Promise (fulfill, reject) ->
			user.xmpp.unsubscribe(jid)
			user.xmpp.removeRosterItem jid, (err, res) ->
				if err
					reject err
				else
					fulfill res

VCard =
		
	read: (user, jid) ->
		return new Promise (fulfill, reject) ->
			user.xmpp.getVCard jid, (err, res) ->
				if err
					if err.error?.condition == 'item-not-found'
						fulfill _.extend {}, jid: jid
					else reject err
				else 
					fulfill _.extend res.vCardTemp, jid: jid
				
	update: (user, jid, data) ->
		return new Promise (fulfill, reject) ->
			user.xmpp.publishVCard data, (err, res) ->
				if err
					reject err
				else
					fulfill data
	
module.exports = 
	Bookmark:	Bookmark
	Room:		Room
	Roster:		Roster
	VCard:		VCard