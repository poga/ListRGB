angular.module 'app.controllers', <[ui.keypress angularLocalStorage ui.sortable monospaced.elastic]>
.controller AppCtrl: <[$scope storage $location $window]> ++ ($scope, storage, $location, $window) ->
  storage.bind $scope, \list, defaultValue: []
  $scope.green = 0
  $scope.blue = 0
  $scope.red = 0
  $scope.grey = 0

  $scope.predicate = (x) -> $scope.list.indexOf(x)
  $scope.sorter = "none"

  $scope.headings = []

  $scope.parse-heading = (list) ->
    $scope.headings = []
    list.map (x) ->
      if x.title == /^(#+)\s/
        $scope.headings.push title: x.title.replace(/^(#+)\s/, ''), h: (x.title == /^(#+)\s/).1.length
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
    remove = $window.confirm("Remove Item: #{item.title} ?")
    $scope.list.splice $scope.list.indexOf(item), 1 if remove

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
      $scope.predicate = (x) -> $scope.list.indexOf(x)
      $scope.drag = {'display': 'inline-block'}

  $scope.get-percent = (list, status) ->
    return 0 if list.length == 0
    list.filter((x) -> x.status == status).length * 100.0 / list.length

  do
    newList <- $scope.$watch 'list', _ , true
    $scope.green = $scope.get-percent newList, \green
    $scope.blue = $scope.get-percent newList, \blue
    $scope.red = $scope.get-percent newList, \red
    $scope.grey = 100 - $scope.green - $scope.blue - $scope.red

  console.log $location.path!

angular.module 'app', <[app.controllers]> ($locationProvider) ->
  $locationProvider.html5Mode true

