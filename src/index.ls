angular.module 'app.controllers', <[ui.keypress angularLocalStorage ui.sortable monospaced.elastic]>
.controller AppCtrl: <[$scope storage $location]> ++ ($scope, storage, $location) ->
  storage.bind $scope, \list, defaultValue: []
  $scope.green = 0
  $scope.blue = 0
  $scope.red = 0
  $scope.grey = 0

  $scope.predicate = 'none'
  $scope.sorter = "none"

  $scope.parse-heading = (list) ->
    list.map (x) ->
      if x.title == /^(#+)\s/ 
        x <<< h: (x.title == /^(#+)\s/).1.length
      else
        delete x.h
        x

  $scope.$watch 'list', $scope.parse-heading, true

  $scope.add = ->
    $scope.list.unshift title: $scope.newItem, status: \none, createdAt: Date.now!
    $scope.newItem = ""

  $scope.setStatus = (item, status) ->
    if item.status == status
      $scope.list[$scope.list.indexOf(item)] = item <<< status: \none
    else
      $scope.list[$scope.list.indexOf(item)] = item <<< status: status

  $scope.removeItem = (item) ->
    $scope.list.splice $scope.list.indexOf(item), 1

  $scope.sortBy = (sorter) ->
    $scope.sorter = sorter
    switch sorter
    case 'status'
      $scope.predicate = (x) ->
        switch x.status
        | \none => 0
        | \green => 1
        | \blue => 2
        | \red => 3
      $scope.drag = {'display': 'none'}
    case 'none'
      $scope.predicate = 'none'
      $scope.drag = {'display': 'inline-block'}

  do
    newList <- $scope.$watch 'list', _ , true
    if newList.length == 0
      $scope.green = 0
      $scope.blue = 0
      $scope.red = 0
      $scope.grey = 0
    else
      $scope.green = newList.filter((x) -> x.status == \green ).length / newList.length * 100
      $scope.blue = newList.filter((x) -> x.status == \blue ).length / newList.length * 100
      $scope.red = newList.filter((x) -> x.status == \red ).length / newList.length * 100
      $scope.grey = newList.filter((x) -> x.status == \none ).length / newList.length * 100

  console.log $location.path!

angular.module 'app', <[app.controllers]> ($locationProvider) ->
  $locationProvider.html5Mode true

