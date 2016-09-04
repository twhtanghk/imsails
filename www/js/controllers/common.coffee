util = require 'util'
env = require '../env.coffee'
_ = require 'lodash'

module.exports = (angularModule) ->
	angularModule
		.factory 'ErrorService', ->
			formErr: (form, err) ->
				_.each err.data.fields, (value, key) ->
					_.extend form[key].$error, server: err.data.fields[key]
				
		.config ($stateProvider) ->
			$stateProvider.state 'app',
				url: ""
				abstract: true
				controller: 'MenuCtrl'
				templateUrl: "templates/menu.html"
				resolve: 
					resource: 'resource'
					model: (resource) ->
						resource.User.me().$fetch()				
		
		.controller 'MenuCtrl', ($scope, resource, model) ->
			_.extend $scope,
				env: env
				resource: resource
				model: model
				
			$scope.$watch 'model.status', (newvalue, oldvalue) ->
				if newvalue != oldvalue
					data = new resource.User id: $scope.model.id
					data.$save(status: $scope.model.status)
		
		.run (toastr) ->
			window.alert = (msg) ->
				toastr.error util.inspect(msg)
