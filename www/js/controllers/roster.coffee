lib = require './lib.coffee'

domain =
	state: ($stateProvider) ->
		$stateProvider.state 'app.roster',
			url: "/roster"
			abstract: true
			views:
				menuContent:
					templateUrl: "templates/roster/index.html"
		
		$stateProvider.state 'app.roster.list',
			cache:	false
			url: 	"/list"
			views:
				rosterContent:
					templateUrl: 'templates/roster/list.html'
					controller: 'RosterCtrl'
			resolve:
				resource: 'resource'
				collection: (resource) ->
					ret = resource.Roster.instance()
					ret.$fetch reset: true
			onExit: ->
				# no more listen to those registered events
				_.each ['connect', 'user', 'group', 'roster'], (event) ->
					io.socket?.removeAllListeners event
		
	item: ($rootScope, $scope, resource) ->
		_.extend $scope,
			remove: ->
				$scope.collection.remove $scope.model
			select: ->
				roster = $scope.model
				if roster.type == 'groupchat'
					$rootScope.$broadcast "group:select", roster.group, roster
				else
					$rootScope.$broadcast "user:select", roster.user, roster
				
		# listen if user status is updated
		io.socket?.on "user", (event) ->
			if event.verb == 'updated' and event.id == $scope.model.user?.id
				_.extend $scope.model.user, new resource.User event.data
				$scope.$apply 'model'
		
		# listen if group status is updated
		io.socket?.on "group", (event) ->
			if event.verb == 'updated' and event.id == $scope.model.group?.id
				_.extend $scope.model.group, new resource.Group event.data
				$scope.$apply 'model'
				
		# listen if roster item is updated
		io.socket?.on "roster", (event) ->
			if event.verb == 'updated' and event.id == $scope.model.id
				_.extend $scope.model, new resource.RosterItem event.data
				$scope.$apply 'model'
						
	list: ($scope, $location, collection) ->
		_.extend $scope,
			searchText:		''
			collection:		collection
			loadMore: ->
				collection.$fetch()
					.then ->
						$scope.$broadcast('scroll.infiniteScrollComplete')
					.catch alert
				return @
				
		# reload collection once reconnected
		io.socket?.on 'connect', (event) ->
			if $location.url().indexOf('/roster/list') != -1
				$scope.collection.$refetch()

filter =		
	list: ->
		(roster, search) ->
			r = new RegExp(search, 'i')
			userSearch = (user) ->
				r.test(user?.jid) or r.test(user?.email) or r.test(user?.fullname()) or r.test(user?.post())
			grpSearch = (group) ->	
				r.test(group?.jid) or r.test(group?.name)
			if search
				return _.filter roster, (item) ->
					userSearch(item.user) or grpSearch(item.group)
			else
				return roster
		
module.exports = (angularModule) ->
	angularModule
		.config ['$stateProvider', domain.state]
		.controller 'RosterItemCtrl', ['$rootScope', '$scope', 'resource', domain.item]
		.controller 'RosterCtrl', ['$scope', '$location', 'collection', domain.list]
		.filter 'rosterFilter', filter.list