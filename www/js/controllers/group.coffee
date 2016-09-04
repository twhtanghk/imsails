lib = require './lib.coffee'

domain =
	state: ($stateProvider) ->
		$stateProvider.state 'app.group',
			url: "/group"
			abstract: true
			views:
				menuContent:
					templateUrl: "templates/group/index.html"
		
		$stateProvider.state 'app.group.create',
			cache: false
			url: "/create"
			views:
				groupContent:
					templateUrl: 'templates/group/create.html'
					controller: 'GroupCreateCtrl'
			resolve:
				resource: 'resource'
				model: (resource) ->
					new resource.Group() 
			
		$stateProvider.state 'app.group.update',
			cache: false
			url: "/update/:id"
			views:
				groupContent:
					templateUrl: 'templates/group/update.html'
					controller: 'GroupUpdateCtrl'
			resolve:
				id: ($stateParams) ->
					$stateParams.id
				resource: 'resource'
				model: (resource, id) ->
					ret = new resource.Group id: id
					ret.$fetch()
						
		$stateProvider.state 'app.group.list',
			url: "/list"
			abstract: true
			views:
				groupContent:
					templateUrl: 'templates/group/list.html'
					controller: ($scope, $location) ->
						_.extend $scope,
							searchText:	''
							$location:	$location
					
		$stateProvider.state 'app.group.list.public',
			cache:	false
			url: 	"/public"
			views:
				tabPublic:
					templateUrl: 'templates/group/tab.html'
					controller: 'GroupsCtrl'
			resolve:
				resource: 'resource'
				collection: (resource) ->
					resource.Groups.instance().$fetch reset: true
			onExit: ->
				# no more listen to those registered events
				_.each ['connect', 'group'], (event) ->
					io.socket?.removeAllListeners event
					
		$stateProvider.state 'app.group.list.private',
			cache:	false
			url: "/private"
			views:
				tabPrivate:
					templateUrl: 'templates/group/tab.html'
					controller: 'GroupsCtrl'
			resolve:
				resource: 'resource'
				collection: (resource) ->
					resource.GroupsPrivate.instance().$fetch reset: true
			onExit: ->
				_.each ['connect', 'group'], (event) ->
					io.socket?.removeAllListeners event

		$stateProvider.state 'app.group.read',
			cache: false
			url: "/:id"
			views:
				groupContent:
					templateUrl: 'templates/group/read.html'
					controller: 'GroupReadCtrl'
			resolve:
				id: ($stateParams) ->
					$stateParams.id
				resource: 'resource'
				model: (resource, id) ->
					ret = new resource.Group id: id
					ret.$fetch()
					
	item: ($rootScope, $scope, $location, resource) ->
		_.extend $scope,
			edit: ->
				$location.url "/group/update/#{$scope.model.id}"
			remove: ->
				$scope.collection.remove $scope.model
			addRoster: ->
				item = new resource.RosterItem
					type: 'groupchat'
					group: $scope.model
				item.$save()
			select: ->
				$rootScope.$broadcast 'group:select', $scope.model
					
		# listen if user status is updated
		io.socket?.on "group", (event) ->
			if event.verb == 'updated' and event.id == $scope.model.id
				_.extend $scope.model, new resource.Group event.data
				$scope.$apply 'model'
		
	list: ($scope, $location, resource, collection) ->
		_.extend $scope,
			collection:		collection
			me:				resource.User.me()
			loadMore: ->
				collection.$fetch()
					.then ->
						$scope.$broadcast('scroll.infiniteScrollComplete')
				return @
				
		# reload collection once reconnected
		io.socket?.on 'connect', (event) ->
			if $location.url().indexOf('/group/list') != -1
				$scope.collection.$refetch()
				
	create: ($scope, $state, resource, model, ErrorService) ->
		_.extend $scope,
			resource: resource
			model: model
			users:		resource.Users.instance()
			select: (files) ->
				if files.length != 0
					lib.readFile(files)
						.then (inImg) ->
							$scope.$emit 'cropImg', inImg 
			save: ->
				$scope.model.$save()
					.then ->
						next = 'app.group.list.public'
						if $scope.model.type == 'Members-Only'
							next = 'app.group.list.private' 
						$state.go next
					.catch (err) ->
						ErrorService.formErr $scope.groupCreate, err
						
		$scope.$on 'cropImg.completed', (event, outImg) ->
			$scope.model.photoUrl = outImg
		
	update: ($scope, $state, resource, model) ->
		_.extend $scope,
			resource:	resource
			model: 		model
			users:		resource.Users.instance()
			select: (files) ->
				if files.length != 0
					lib.readFile(files)
						.then (inImg) ->
							$scope.$emit 'cropImg', inImg 
			save: ->
				if model.photoUrl?.match(/^data:(.+);base64,(.*)$/)
					model.photo = model.photoUrl
				model.$save()
					.then ->
						next = 'app.group.list.public'
						if model.type == 'Members-Only'
							next = 'app.group.list.private' 
						$state.go next
		
		$scope.$on 'cropImg.completed', (event, outImg) ->
			$scope.model.photoUrl = outImg		
			
filter = 
	list: ->
		(collection, search) ->
			if search
				return _.filter collection, (item) ->
					r = new RegExp(search, 'i')
					r.test(item.name) or r.test(item.jid)
			else
				return collection
			
module.exports = (angularModule) ->
	angularModule
		.config ['$stateProvider', domain.state]
		.controller 'GroupCtrl', ['$rootScope', '$scope', '$location', 'resource', domain.item]
		.controller 'GroupsCtrl', ['$scope', '$location', 'resource', 'collection', domain.list]
		.controller 'GroupCreateCtrl', ['$scope', '$state', 'resource', 'model', 'ErrorService', domain.create]
		.controller 'GroupUpdateCtrl', ['$scope', '$state', 'resource', 'model', domain.update]
		.filter 'groupFilter', filter.list
		
		.run ($rootScope, $ionicActionSheet, $translate, $location, $ionicHistory, resource) ->
			$rootScope.$on 'group:select', (event, group, rosterItem) ->
				$translate ['Info', 'Exit', 'Edit', 'Delete', 'Cancel']
					.then (translations) -> 
						info =
							type:	'button'
							text:	translations['Info']
							show:	true
							cb:		->
								$location.path("/group/#{group.id}")
						exit =
							type:	'button'
							text:	translations['Exit']
							show:	resource.User.me().isModerator(group) or resource.User.me().isMember(group)
							cb:		->
								group.exit()
									.then ->
										if rosterItem
											resource.Roster.instance().remove rosterItem
										close()
						edit =
							type:	'button'
							text:	translations['Edit']
							show:	resource.User.me().canEdit(group)
							cb:		->
								$location.path("/group/update/#{group.id}")
						del =
							type:	'destructive'
							text:	translations['Delete']
							show:	resource.User.me().canRemove(group)
							cb:		->
								if rosterItem
									resource.Roster.instance().remove rosterItem
								else 
									collection = if group.type == 'Members-Only' then resource.GroupsPrivate else resource.Groups
									collection.instance().remove group
								close()
						cancel =
							type:	'cancel'
							text:	translations['Cancel']
							show:	true
						close = $ionicActionSheet.showAction
							action: [info, exit, edit, del, cancel] 
		
		.controller 'GroupReadCtrl', ($scope, resource, model) ->
			_.extend $scope,
				resource:	resource
				model:		model
