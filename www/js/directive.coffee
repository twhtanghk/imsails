angular
  .module 'util.directive', []
  .directive 'focusOn', ($timeout) ->
    restrict: 'A'
    link: ($scope, $element, $attr) ->
      $scope.$watch $attr.focusOn, (val) ->
        $timeout ->
          if val
            $element[0].focus()
          else
            $element[0].blur()
