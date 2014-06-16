angular.module 'app.controllers', <[ui.keypress angularLocalStorage ui.sortable]>
.controller AppCtrl: <[$scope storage $location]> ++ ($scope, storage, $location) ->
  storage.bind $scope, \list, defaultValue: []
  $scope.green = 0
  $scope.blue = 0
  $scope.red = 0
  $scope.grey = 0

  $scope.add = ->
    $scope.list.unshift title: $scope.newItem, status: \none
    $scope.newItem = ""

  $scope.setStatus = (item, status) ->
    if item.status == status
      $scope.list[$scope.list.indexOf(item)] = item <<< status: \none
    else
      $scope.list[$scope.list.indexOf(item)] = item <<< status: status

  $scope.removeItem = (item) ->
    $scope.list.splice $scope.list.indexOf(item), 1

  do
    newList <- $scope.$watch 'list', _ , true
    $scope.green = newList.filter((x) -> x.status == \green ).length / newList.length * 100
    $scope.blue = newList.filter((x) -> x.status == \blue ).length / newList.length * 100
    $scope.red = newList.filter((x) -> x.status == \red ).length / newList.length * 100
    $scope.grey = newList.filter((x) -> x.status == \none ).length / newList.length * 100

  console.log $location.path!

angular.module 'app', <[app.controllers]> ($locationProvider) ->
  $locationProvider.html5Mode true

