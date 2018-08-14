env = require '../env.coffee'
path = require 'path'
sails =
	services:
		file:	require '../../../api/services/file.coffee'
mime = require 'mime-types'

angular

	.module 'starter.controller'

	.config ($stateProvider) ->
		$stateProvider.state 'app.chat',
			url: "/chat"
			abstract: true
			views:
				menuContent:
					templateUrl: "templates/chat/index.html"

		$stateProvider.state 'app.chat.list',
			cache: false

			url: "/:type/:id"

			views:
				chatContent:
					templateUrl: 'templates/chat/list.html'
					controller: 'ChatCtrl'
			resolve:
				resource: 'resource'
				type: ($stateParams) ->
					$stateParams.type
				id: ($stateParams) ->
					$stateParams.id
				chat: (resource, type, id) ->
					ret = if type == 'chat' then new resource.User id: id else new resource.Group id: id
					ret.$fetch()
				me: (resource) ->
					resource.User.me()
				collection: (type, chat, resource) ->
					ret = new resource.Msgs()
					ret.$fetch params: {type: type, to: chat.jid, sort: 'createdAt DESC'}

			onExit: (resource, chat) ->
				# clear roster newmsg counter
				item = _.find resource.Roster.instance().models, jid: chat.jid
				item?.$save(newmsg: 0)

				# no more listen to those registered events
				io.socket?.removeAllListeners 'msg'

	.controller 'ChatCtrl', ($scope, $cordovaClipboard, $log, $ionicScrollDelegate, $location, type, chat, me, collection, resource, $cordovaFileTransfer, $http, audioService) ->
		_.extend $scope,
			type: type
			chat: chat
			me: me
			collection: collection
			msg: ''
			loadMore: ->
				collection.$fetch params: {type: type, to: chat.jid, sort: 'createdAt DESC'}
					.then ->
						$scope.$broadcast('scroll.infiniteScrollComplete')
				return @
			creating: ->
				_.find collection.models, (msg) ->
					msg.$isNew()
			addFile: (files) ->
				if files?.length != 0
					$scope.addMsg
						local: files[0]
						file:
							url: files[0].localURL || URL.createObjectURL files[0]
							name: files[0].name
							type: files[0].type
							base: files[0].name
							ext: path.extname files[0].name
						file_inode: contentType: files[0].type || mime.lookup files[0].name
			addMsg: (attrs = {}) ->
				_.defaults attrs,
					type: type
					to: chat.jid
					body: ''
				msg = new resource.Msg attrs
				Promise
					.try ->
						socket = io.socket?._raw
						if socket?.connected
							Promise.resolve()
						else
							new Promise (resolve, reject) ->
								socket?.once 'connect', resolve
								socket?.once 'error', reject
					.then ->
						# send attachment if it is audio or video file
						if /^blob/.test(msg.file?.url) and msg.msgType() in ['audio', 'video'] and env.isMobile()
							return msg.$save().catch $log.error
						collection.add msg
						$scope.$apply 'collection.models'
						$ionicScrollDelegate.scrollTop true
					.catch $log.error
			recording: false
			copy: (msg) ->
				if env.isNative()
					$cordovaClipboard.copy(msg.body)
						.then ->
							$log.info 'Message copied'
						.catch $log.error

		# reload collection once reconnected
		io.socket?.on 'connect', (event) ->
			if $location.url().indexOf('/chat') != -1
				$scope.collection.$refetch params: {type: type, to: chat.jid, sort: 'createdAt DESC'}

		# listen if msg is created on server
		isValid = (msg) ->
			if type == 'chat'
				return (msg.from == chat.jid and msg.to == me.jid) or (msg.to == chat.jid and msg.from == me.jid)
			else
				return msg.to == chat.jid
		io.socket?.on "msg", (event) ->
			if event.verb == 'created' and isValid(event.data)
				collection.add new resource.Msg event.data
				$scope.$apply 'collection.models'
				$ionicScrollDelegate.scrollTop true

		audioService.recorder.on 'start', ->
			$scope.recording = true
		audioService.recorder.on 'stop', ->
			$scope.addFile [audioService.recorder.file]
			$scope.recording = false
		$scope.$on '$destroy', ->
			audioService.recorder.removeAllListeners()

	.controller 'msgCtrl', ($scope, resource, $cordovaFileOpener2, $http, fileService, $log) ->
		fs = fileService.fs

		msg = $scope.model

		if msg.file and not msg.$isNew()
			dest = msg.file.org
			switch true
				when sails.services.file.isImg(msg.file_inode) or sails.services.file.isVideo(msg.file_inode)
					thumb = new resource.Thumb _.pick msg, 'id', 'file'
					thumb.$fetch()
						.then ->
							$scope.$apply()
						.catch $log.error
				when sails.services.file.isAudio msg.file_inode
					audio = new resource.Attachment _.pick msg, 'id', 'file'
					audio.$fetch()
						.then ->
							$scope.$apply()
						.catch $log.error

		_.extend $scope,
			send: (msg) ->
				msg
					.$save()
					.catch $log.error
				$scope.cancel(msg)
			cancel: (msg) ->
				_.remove $scope.collection.models, (msg) ->
					msg.$isNew()
			getfile: ->
				file = new resource.Attachment _.pick msg, 'id', 'file'
				switch device.platform
					when 'browser'
						file
							.$saveAs()
					else
						transfer = new fileService.Progress msg.file.base
						file
							.$fetch progress: transfer.progress
							.then ->
								transfer.end()
								$cordovaFileOpener2.open file.file.local, sails.services.file.type(msg.file_inode)
							.catch (err) ->
								transfer.end()
								$log.error err

	.controller 'AudioCtrl', ($scope, $cordovaDevice, $cordovaCapture, $log) ->
		$scope.start = ->
			$cordovaCapture.captureAudio()
				.then (files) ->
					$scope.addFile files
				# ignore caputre error and show as debug only
				.catch $log.debug 

	.filter 'msgFilter', ->
		(msgs, search) ->
			if search
				return _.filter msgs, (msg) ->
					r = new RegExp RegExp.quote(search), 'i'
					r.test(msg.body) or r.test(msg.file?.base)
			else
				return msgs
