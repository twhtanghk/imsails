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
					io.socket.removeAllListeners event
					
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
					io.socket.removeAllListeners event

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
					
		# listen if user status is updated
		io.socket.on "group", (event) ->
			if event.verb == 'updated' and event.id == $scope.model.id
				_.extend $scope.model, event.data
				$scope.$apply 'model'
		
	list: ($scope, $location, collection) ->
		_.extend $scope,
			collection:		collection
			loadMore: ->
				collection.$fetch()
					.then ->
						$scope.$broadcast('scroll.infiniteScrollComplete')
					.catch alert
				return @
				
		# reload collection once reconnected
		io.socket.on 'connect', (event) ->
			if $location.url().indexOf('/group/list') != -1
				$scope.collection.$fetch reset: true
	
	create: ($scope, $state, resource, model) ->
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
					.catch alert
		
		$scope.$on 'cropImg.completed', (event, outImg) ->
			$scope.model.photoUrl = outImg
		
	update: ($scope, $state, resource, model) ->
		_.extend $scope,
			resource: resource
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
					.catch alert
		
		$scope.$on 'cropImg.completed', (event, outImg) ->
			$scope.model.photoUrl = outImg		
			
filter = 
	list: ->
		(collection, search) ->
			if search
				return _.filter collection, (item) ->
					item.name.indexOf(search) > -1
			else
				return collection
			
module.exports = (angularModule) ->
	angularModule
		.config ['$stateProvider', domain.state]
		.controller 'GroupCtrl', ['$rootScope', '$scope', '$location', 'resource', domain.item]
		.controller 'GroupsCtrl', ['$scope', '$location', 'collection', domain.list]
		.controller 'GroupCreateCtrl', ['$scope', '$state', 'resource', 'model', domain.create]
		.controller 'GroupUpdateCtrl', ['$scope', '$state', 'resource', 'model', domain.update]
		.filter 'groupFilter', filter.list