angular.module 'app.controllers', <[ui.keypress angularLocalStorage]>
.controller AppCtrl: <[$scope storage $location]> ++ ($scope, storage, $location) ->
  storage.bind $scope, \list, defaultValue: []
  $scope.add = ->
    $scope.list.unshift title: $scope.newItem
    $scope.newItem = ""

  $scope.toggleItem = (id) ->
    console.log id

  console.log $location.path!

angular.module 'app', <[app.controllers]> ($locationProvider) ->
  $locationProvider.html5Mode true
