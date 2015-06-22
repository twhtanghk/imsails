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
		$urlRoot: "#{env.server.app.url}/api/roster"
		
		$parse: (data, opts) ->
			ret = super(data, opts)
			_.each ['updatedAt', 'createdAt'], (field) ->
				if ret[field]
					ret[field] = new Date Date.parse ret[field]				
			return ret
			
	class Roster extends pageableAR.PageableCollection
		_instance = null
		
		$urlRoot: "#{env.server.app.url}/api/roster"
		
		model: RosterItem

		@instance: ->
			_instance ?= new Roster()
		
	class User extends pageableAR.Model
		_me = null
		
		$urlRoot: "#{env.server.app.url}/api/user"
		
		@me: ->
			_me ?= new User id: 'me'
			
		$parse: (data, opts) ->
			ret = super(data, opts)
			_.each ['updatedAt', 'createdAt'], (field) ->
				if ret[field]
					ret[field] = new Date Date.parse ret[field]				
			return ret
			
	class Users extends pageableAR.PageableCollection
		_instance = null
		
		$urlRoot: "#{env.server.app.url}/api/user"
		
		model: User
	
		@instance: ->
			_instance ?= new Users()
			
	class Msg extends pageableAR.Model
		$urlRoot: "#{env.server.app.url}/api/msg"
		
		$parse: (data, opts) ->
			ret = super(data, opts)
			_.each ['updatedAt', 'createdAt'], (field) ->
				ret[field] = new Date Date.parse ret[field]				
			return ret
		
	class Msgs extends pageableAR.PageableCollection
		$urlRoot: "#{env.server.app.url}/api/msg"
		
		model: Msg
		
	User:		User
	Users:		Users
	RosterItem:	RosterItem
	Roster:		Roster
	Msg:		Msg
	Msgs:		Msgs

angular.module('starter.model', ['ionic', 'PageableAR'])
	.value 'server', env.server.app
	.factory 'resource', ['$rootScope', 'pageableAR', resource]