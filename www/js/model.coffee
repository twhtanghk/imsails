env = require './env.coffee'
require 'PageableAR'
_ = require 'lodash'
path = require 'path'
sails =
	services:
		user:	require '../../api/services/user.coffee'
		
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
		
urlRoot = (root, url, type = env.server.app.type) ->
	if type == 'io' then "/#{url}" else "#{root}/#{url}"
		
resource = ($rootScope, pageableAR, Upload, $cordovaFileTransfer, $http) ->
	
	class RosterItem extends pageableAR.Model
		$urlRoot: urlRoot(env.server.app.urlRoot, "api/roster") 
		
		$parse: (data, opts) ->
			ret = super(data, opts)
			
			_.each ['updatedAt', 'createdAt', 'lastmsgAt'], (field) ->
				if ret[field]
					ret[field] = new Date Date.parse ret[field]
			
			if ret.user
				ret.user = new User ret.user 				
			
			if ret.group
				ret.group = new Group ret.group
					
			return ret
			
	class Roster extends pageableAR.PageableCollection
		_instance = null
		
		$urlRoot: urlRoot(env.server.app.urlRoot, "api/roster")
		
		model: RosterItem

		@instance: ->
			_instance ?= new Roster()

	class User extends pageableAR.Model
		@type:
			placeholder:
				phone:		'Phone'
				otherEmail:	'Email'
				address:	'Address'
			values:
				phone:		['Mobile', 'Office', 'Home', 'Other']
				otherEmail:	['Office', 'Personal', 'Other']
				address:	['Office', 'Home', 'Other']
			status:		['Available', 'Meeting', 'Busy', 'Vacation', 'Sick', 'Training', 'Home', 'Other']
			
		_me = null
		
		$urlRoot: urlRoot(env.server.app.urlRoot, "api/user")
		
		@me: ->
			_me ?= new User id: 'me'
			
		$parse: (data, opts) ->
			ret = super(data, opts)
			_.each ['updatedAt', 'createdAt'], (field) ->
				if ret[field]
					ret[field] = new Date Date.parse ret[field]
			return ret
			
		$save: (values, opts) ->
			@promise = super(values, opts)
			
		post: ->
			sails.services.user.post(@)
			
		fullname: ->
			sails.services.user.fullname(@)
			
		isOwner: (group) ->
			sails.services.user.isOwner(@, group)
			
		isModerator: (group) ->
			sails.services.user.isModerator(@, group)
				
		isMember: (group) ->
			sails.services.user.isMember(@, group)
			
		isVisitor: (group) ->
			sails.services.user.isVisitor(@, group)

		# check if user is authorized to enter the chatroom
		canEnter: (group) ->
			sails.services.user.canEnter(@, group)
			
		# check if user is authorized to send message to the chatroom
		canVoice: (group) ->
			sails.services.user.canVoice(@, group)
			
		# check if user is authorized to edit the group settings
		canEdit: (group) ->
			sails.services.user.canEdit(@, group)
		
		# check if user is authorized to remove this group
		canRemove: (group) ->
			sails.services.user.canRemove(@, group)
		
	class Users extends pageableAR.PageableCollection
		_instance = null
		
		$urlRoot: urlRoot(env.server.app.urlRoot, "api/user")
		
		model: User
	
		@instance: ->
			_instance ?= new Users()
			if _instance.state.count == 0
				_instance.$fetch()
			return _instance			

	class Group extends pageableAR.Model
		@type:
			placeholder:
				moderators:	'Moderators'
				members:	'Members'
				visitors:	'Visitors'
			values: ['Members-Only', 'Unmoderated', 'Moderated']
		
		$urlRoot: urlRoot(env.server.app.urlRoot, "api/group")
		
		$defaults:
			type:		'Members-Only'
			moderators:	[]
			members:	[]
			visitors:	[]
			
		$parse: (data, opts) ->
			ret = super(data, opts)
			
			_.each ['updatedAt', 'createdAt'], (field) ->
				if ret[field]
					ret[field] = new Date Date.parse ret[field]
			
			if ret.members
				ret.members = _.map ret.members, (user) ->
					new User user
					
			return ret
		
	# public groups
	class Groups extends pageableAR.PageableCollection
		_instance = null
		
		$urlRoot: urlRoot(env.server.app.urlRoot, "api/group")
		
		model: Group
		
		@instance: ->
			_instance ?= new Groups()
	
	# membersOnly groups
	class GroupsPrivate extends pageableAR.PageableCollection
		_instance = null
		
		$urlRoot: urlRoot(env.server.app.urlRoot, "api/group/membersOnly")
		
		model: Group
		
		@instance: ->
			_instance ?= new GroupsPrivate()
	
	class Msg extends pageableAR.Model
		$urlRoot: urlRoot(env.server.app.urlRoot, "api/msg")
		
		$parse: (data, opts) ->
			ret = super(data, opts)
			_.each ['updatedAt', 'createdAt'], (field) ->
				ret[field] = new Date Date.parse ret[field]
			if ret.file and typeof ret.file == 'string'
				ret.file =
					org:	ret.file
					base:	path.basename ret.file 
					ext:	path.extname(ret.file)[1..]
			return ret
		
	class Attachment extends pageableAR.Model
		$urlRoot: urlRoot(env.server.app.urlRoot, "api/msg/file", 'rest')
		
		$save: (values = {}, opts = {}) ->
			_.extend @, values
			data = 
				url: 	@$url()
				fields:	_.pick @, 'to', 'type'
				file:	@file
			new Promise (fulfill, reject) ->
				Upload
					.upload(data)
					.progress (event) ->
						return
					.success fulfill
					.error reject
					
		$fetch: (opts = {}) ->
			opts = _.defaults opts, 
				responseType: 	'blob'
				headers: 		$http.defaults.headers.common
			switch device.platform
				when 'browser'
					new Promise (fulfill, reject) =>
						@$sync('read', @, opts)
							.then (res) ->
								contentType = res.headers('Content-type')
								saveAs new Blob([res.data], type: contentType), opts.target
								fulfill(res)
							.catch reject
				when 'Android'
					$cordovaFileTransfer
						.download @$url(), opts.target, opts, true

		$sync: (op, model, opts) ->
			@restsync(op, model, opts)

	class Msgs extends pageableAR.PageableCollection
		$urlRoot: urlRoot(env.server.app.urlRoot, "api/msg")
		
		model: Msg
		
	class Device extends pageableAR.Model
		$urlRoot: urlRoot(env.server.mobile.urlRoot, "api/device", 'rest')
	
		$sync: (op, model, opts) ->
			@restsync(op, model, opts)
	
	User:			User
	Users:			Users
	Group:			Group
	Groups:			Groups
	GroupsPrivate:	GroupsPrivate
	RosterItem:		RosterItem
	Roster:			Roster
	Msg:			Msg
	Attachment:		Attachment
	Msgs:			Msgs
	Device:			Device

angular.module('starter.model', ['ionic', 'PageableAR', 'ngFileUpload'])
	.value 'server', env.server.app
	.factory 'resource', ['$rootScope', 'pageableAR', 'Upload', '$cordovaFileTransfer', '$http', resource]