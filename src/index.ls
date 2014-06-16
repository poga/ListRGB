angular.module 'app.controllers', <[ui.keypress angularLocalStorage ui.sortable monospaced.elastic]>
.controller AppCtrl: <[$scope storage $location]> ++ ($scope, storage, $location) ->
  storage.bind $scope, \list, defaultValue: []
  $scope.green = 0
  $scope.blue = 0
  $scope.red = 0
  $scope.grey = 0

  $scope.predicate = 'none'
  $scope.sorter = "none"

  $scope.headings = []

  $scope.parse-heading = (list) ->
    $scope.headings = []
    list.map (x) ->
      if x.title == /^(#+)\s/
        $scope.headings.push title: x.title, h: (x.title == /^(#+)\s/).1.length
        x <<< h: (x.title == /^(#+)\s/).1.length
      else
        delete x.h
        x

  $scope.$watch 'list', $scope.parse-heading, true

  $scope.add = ->
    $scope.list.unshift title: $scope.newItem, status: \none, createdAt: Date.now!
    $scope.newItem = ""

  $scope.set-status = (item, status) ->
    if item.status == status
      $scope.list[$scope.list.indexOf(item)] = item <<< status: \none
    else
      $scope.list[$scope.list.indexOf(item)] = item <<< status: status

  $scope.remove-item = (item) ->
    $scope.list.splice $scope.list.indexOf(item), 1

  $scope.sort-by = (sorter) ->
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

  $scope.get-percent = (list, status) ->
    return 0 if list.length == 0
    list.filter((x) -> x.status == status).length / list.length * 100

  do
    newList <- $scope.$watch 'list', _ , true
    $scope.green = $scope.get-percent newList, \red
    $scope.blue = $scope.get-percent newList, \blue
    $scope.red = $scope.get-percent newList, \red
    $scope.grey = $scope.get-percent newList, \none

  console.log $location.path!

angular.module 'app', <[app.controllers]> ($locationProvider) ->
  $locationProvider.html5Mode true

