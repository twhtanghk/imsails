env = require './env.coffee'
require 'PageableAR'
_ = require 'lodash'
sails =
	services:
		user:	require '../../api/services/user.coffee'
		file:	require '../../api/services/file.coffee'
		
urlRoot = (model, url, root = env.server.app.urlRoot) ->
	if model.transport() == 'io' then "/#{url}" else "#{root}/#{url}"
		
angular.module('starter.model', ['ionic', 'PageableAR', 'util.file'])
	
	.factory 'resource', (pageableAR, $http, fileService) ->
	
		pageableAR.setTransport(pageableAR.Model.iosync)
		
		class RosterItem extends pageableAR.Model
			$urlRoot: ->
				urlRoot @, "api/roster" 
			
			$parse: (data, opts) ->
				ret = super(data, opts)
				
				_.each ['updatedAt', 'createdAt', 'lastmsgAt'], (field) ->
					if ret[field]
						ret[field] = new Date Date.parse ret[field]
				
				if ret.user
					ret.user = new User ret.user 				
				
				if ret.group
					ret.group = new Group ret.group
					ret.group.$fetch(reset: true).catch alert
						
				return ret
				
		class Roster extends pageableAR.PageableCollection
			_instance = null
			
			$urlRoot: ->
				urlRoot @, "api/roster"
			
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
			
			$urlRoot: ->
				urlRoot @, "api/user"
			
			@me: ->
				_me ?= new User id: 'me'
				
			$parse: (data, opts) ->
				ret = super(data, opts)
				_.each ['updatedAt', 'createdAt'], (field) ->
					if ret[field]
						ret[field] = new Date Date.parse ret[field]
				return ret
				
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
			
			$urlRoot: ->
				urlRoot @, "api/user"
			
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
				values: ['Members-Only', 'Moderated', 'Unmoderated']
			
			$urlRoot: ->
				urlRoot @, "api/group"
			
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
				
				if ret.moderators
					ret.moderators = _.map ret.moderators, (user) ->
						new User user
						
				if ret.members
					ret.members = _.map ret.members, (user) ->
						new User user
						
				if ret.createdBy and typeof ret.createdBy == 'object'
					ret.createdBy = new User ret.createdBy
					
				return ret
			
			exit: ->
				@$save {}, url: "#{@$url()}/exit"
				
		# public groups
		class Groups extends pageableAR.PageableCollection
			_instance = null
			
			$urlRoot: ->
				urlRoot @, "api/group"
			
			model: Group
			
			@instance: ->
				_instance ?= new Groups()
		
		# membersOnly groups
		class GroupsPrivate extends pageableAR.PageableCollection
			_instance = null
			
			$urlRoot: ->
				urlRoot @, "api/group/membersOnly"
			
			model: Group
			
			@instance: ->
				_instance ?= new GroupsPrivate()
		
		class Msg extends pageableAR.Model
			$urlRoot: ->
				urlRoot @, "api/msg"
	
			@msgType: (msg) ->
				if msg.file
					switch true
						when sails.services.file.isImg(msg.file.base)
							return 'img'
						when sails.services.file.isAudio(msg.file.base)
							return 'audio' 
						else 
							return 'file'
				else
					return 'msg'
					
			msgType: ->
				Msg.msgType @
				
			templateUrl: ->
				"templates/chat/#{@msgType()}.html"
				
			$parse: (data, opts) ->
				ret = super(data, opts)
				_.each ['updatedAt', 'createdAt'], (field) ->
					ret[field] = new Date Date.parse ret[field]
				switch Msg.msgType(data)
					when 'img'
						ret.thumb = new Thumb data
						ret.thumb.$fetch()
							.catch alert
					when 'audio'
						ret.attachment = new Attachment data
					when 'file'
						ret.attachment = new Attachment data
					when 'msg'
						break
					else
						break
				return ret
			
		class Attachment extends pageableAR.Model
			$urlRoot: ->
				urlRoot @, "api/msg/file"
			
			isImg: ->
				sails.services.file.isImg(@file)
					
			$save: (values = {}, opts = {}) ->
				_.extend @, values
				_.extend opts, data: _.pick(@, 'to', 'type')
				transfer = new fileService.FileTransfer @local, @$url()
				transfer.upload(opts)
						
			$fetch: (opts = {}) ->
				opts = _.defaults opts, 
					responseType: 	'blob'
				fileService.FileSystem.requestFileSystem()
					.then (fs) =>
						fs.create @file.org
							.then (entry) =>
								@local = entry
								transfer = new fileService.FileTransfer	@local, @$url()
								transfer.download(opts)
				
			$saveAs: ->
				transfer = new fileService.FileTransfer	name: @file.base, @$url()
				transfer.saveAs()
				
			localUrl: ->
				@local?.toURL()
				
			@sync: pageableAR.Model.restsync
	
		class Thumb extends Attachment
			$urlRoot: ->
				urlRoot @, "api/msg/file/thumb"
	
			$save: ->
				$log.error 'saving thumb image is not allowed'
				
			$fetch: (opts = {}) ->
				opts = _.defaults opts, 
					responseType: 	'blob'
				fileService.FileSystem.requestFileSystem()
					.then (fs) =>
						fs.create sails.services.file.thumbName(@file.org)
							.then (entry) =>
								@local = entry
								transfer = new fileService.FileTransfer	@local, @$url()
								transfer.download(opts)
					
		class Audio extends Attachment
			$url: ->
				token = $http.defaults.headers.common.Authorization.split(' ')[1]
				"#{super()}?access_token=#{token}"
							
		class Msgs extends pageableAR.PageableCollection
			$urlRoot: ->
				urlRoot @, "api/msg"
			
			model: Msg
			
		class Device extends pageableAR.Model
			$urlRoot: ->
				"#{env.server.mobile.urlRoot}/api/device"
		
			@sync: pageableAR.Model.restsync
		
		User:			User
		Users:			Users
		Group:			Group
		Groups:			Groups
		GroupsPrivate:	GroupsPrivate
		RosterItem:		RosterItem
		Roster:			Roster
		Msg:			Msg
		Attachment:		Attachment
		Thumb:			Thumb
		Audio:			Audio
		Msgs:			Msgs
		Device:			Device