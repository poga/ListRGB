angular.module 'app.controllers', <[ui.keypress angularLocalStorage ui.sortable monospaced.elastic]>
.controller AppCtrl: <[$scope storage $location $window]> ++ ($scope, storage, $location, $window) ->
  storage.bind $scope, \list, defaultValue: []
  $scope.statuses = <[green blue red]>
  $scope.green = 0
  $scope.blue = 0
  $scope.red = 0
  $scope.grey = 0

  $scope.predicate = (x) -> $scope.list.indexOf(x)
  $scope.sorter = "none"

  $scope.headings = []

  $scope.add = ->
    $scope.list.unshift title: $scope.newItem, status: \none, createdAt: Date.now!
    $scope.newItem = ""

  $scope.set-status = (item, status) ->
    $scope.list[$scope.list.indexOf(item)] = if item.status == status
      item <<< status: \none
    else
      item <<< status: status

  $scope.remove-item = (item) ->
    remove = $window.confirm("Remove Item: #{item.title} ?")
    $scope.list.splice $scope.list.indexOf(item), 1 if remove

  $scope.sort-by = (sorter) ->
    $scope.sorter = sorter
    switch sorter
    case 'status'
      $scope.predicate = []
        ..push (x) ->
          switch x.status
          | \none => 0
          | \green => 1
          | \blue => 2
          | \red => 3
        ..push (x) ->
          $scope.list.indexOf(x)
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

