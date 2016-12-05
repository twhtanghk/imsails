util = require 'util'
_ = require 'lodash'

RegExp.quote = (str) ->
  str.replace /([.?*+^$[\]\\(){}|-])/g, "\\$1"

angular

  .module 'starter.controller'

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
        me: (resource) ->
          resource.User.me().$fetch()
        model: (me) ->
          me

  .controller 'MenuCtrl', ($scope, $ionicModal, resource, model) ->
    $ionicModal
      .fromTemplateUrl 'templates/user/currentStatus.html',
        scope: $scope
      .then (modal) ->
        $scope.statusModal = modal
    _.extend $scope,
      resource: resource
      model: model
      select: (status) ->
        $scope.model.status = status
        $scope.statusModal.hide()

    $scope.$watch 'model.status', (newvalue, oldvalue) ->
      if newvalue != oldvalue
        data = new resource.User id: $scope.model.id
        data.$save(status: $scope.model.status)

  .run (toastr) ->
    window.alert = (msg) ->
      toastr.error util.inspect(msg)
