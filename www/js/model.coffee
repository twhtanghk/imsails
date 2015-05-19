env = require './env.coffee'
require 'PageableAR'
_ = require 'lodash'

iconUrl = (type) ->
	icon = 
		"text/directory":				"img/dir.png"
		"text/plain":					"img/txt.png"
		"text/html":					"img/html.png"
		"application/javascript":		"img/js.png"
		"application/octet-stream":		"img/dat.png"
		"application/pdf":				"img/pdf.png"
		"application/excel":			"img/xls.png"
		"application/x-zip-compressed":	"img/zip.png"
		"application/msword":			"img/doc.png"
		"image/png":					"img/png.png"
		"image/jpeg":					"img/jpg.png"
	return if type of icon then icon[type] else "img/unknown.png"
		
resource = ($rootScope, pageableAR) ->
	
	class RosterItem extends pageableAR.Model
		$idAttribute: '_id'
		
		$urlRoot: "#{env.server.app.url}/api/roster"
		
		$parse: (data, opts) ->
			ret = super(data, opts)
			ret.photoUrl = if ret.photo? then "data:#{ret.photo?.type};base64,#{ret.photo?.data}" else "img/photo.png"
			return ret
			
	class Roster extends pageableAR.PageableCollection
		_instance = null
		
		$idAttribute: '_id'
	
		$urlRoot: "#{env.server.app.url}/api/roster"
		
		model: RosterItem

		@instance: ->
			_instance ?= new Roster()
		
	class VCard extends pageableAR.Model
		_me = null
		
		$idAttribute: 'jid'
		
		$urlRoot: "#{env.server.app.url}/api/vcard"
		
		fullname: ->
			if @name?
				"#{@name?.given || ''} #{@name?.middle || ''} #{@name?.family || ''}"
			else
				@jid
			
		post: ->
			if @organization?.name? or @title?
				"#{@organization?.name || ''}/#{@title || ''}"
			else
				""
			
		# return type of data in emails, addresses, phoneNumbers
		# e.g. ['work', 'home']
		type: ->
			ret = []
			data = _.union @emails, @addresses, @phoneNumbers
			_.each data, (entry) ->
				key = _.findKey entry, (value, key) ->
					value == true
				ret.push key
			return _.uniq ret
			
		phone: ->
			ret = {}
			_.map @phoneNumbers, (entry) ->
				key = _.findKey entry, (value, key) ->
					value == true
				ret[key] = entry.number
			return ret
				
		email: ->
			ret = {}
			_.map @emails, (entry) ->
				key = _.findKey entry, (value, key) ->
					value == true
				ret[key] = entry.email
			return ret
		
		addr: ->
			ret = {}
			_.map @addresses, (entry) ->
				key = _.findKey entry, (value, key) ->
					value == true
				ret[key] = entry.street
			return ret
	
		$parse: (data, opts) ->
			ret = super(data, opts)
			ret.photoUrl = if ret.photo? then "data:#{ret.photo?.type};base64,#{ret.photo?.data}" else "img/photo.png"
			return ret
			
		$save: (model, opts = {}) ->
			_.extend @, _.pick(model, 'photoUrl')
			pattern = /data:(.*)(?:;base64),(.*)/
			result = pattern.exec @photoUrl
			@photo =
				type:	result[1]
				data:	result[2]
			super(model, opts)
			
		@me: ->
			_me ?= new VCard jid: 'me'
			
		toggleSelect: (@selected = not @selected) ->
			$rootScope.$broadcast 'vcard:selected', @
			
	class VCards extends pageableAR.PageableCollection
		_instance = null
		
		$idAttribute: 'jid'
		
		$urlRoot: "#{env.server.app.url}/api/vcard"
		
		model: VCard
	
		@instance: ->
			_instance ?= new VCards()
			
	class Chat extends pageableAR.PageableCollection
		$idAttribute: 'jid'
	
		$urlRoot: "#{env.server.app.url}/api/chat"
		
	RosterItem:	RosterItem
	Roster:		Roster
	VCard:		VCard
	VCards:		VCards
	Chat:		Chat

angular.module('starter.model', ['ionic', 'PageableAR'])
	.value 'server', env.server.app
	.factory 'resource', ['$rootScope', 'pageableAR', resource]