angular.module 'app.controllers', <[ui.keypress angularLocalStorage ui.sortable monospaced.elastic]>
.controller AppCtrl: <[$scope storage $location $window]> ++ ($scope, storage, $location, $window) ->
  storage.bind $scope, \list, defaultValue: []

  $scope <<< do
    statuses: <[green blue red]>
    green: 0
    blue: 0
    red: 0
    grey: 0
    categories: []

    predicate: (x) -> $scope.list.indexOf(x)
    sorter: "none"

    parse-tags: (list) ->
      $scope.tags = []
      regex = /\s#(\S+)\s*?/g
      for x, i in list
        if x.title.match regex
          $scope.tags ++= x.title.match regex

    add: ->
      $scope.list.unshift title: $scope.newItem, status: \none, createdAt: Date.now!
      $scope.newItem = ""

    set-status: (item, status) ->
      $scope.list[$scope.list.indexOf(item)] = if item.status == status
        item <<< status: \none
      else
        item <<< status: status

    remove-item: (item) ->
      remove = $window.confirm("Remove Item: #{item.title} ?")
      $scope.list.splice $scope.list.indexOf(item), 1 if remove

    sort-by: (sorter) ->
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

    get-percent: (list, status) ->
      return 0 if list.length == 0
      list.filter((x) -> x.status == status).length * 100.0 / list.length

  $scope.$watch 'list', $scope.parse-tags, true

  do
    newList <- $scope.$watch 'list', _ , true
    $scope.green = $scope.get-percent newList, \green
    $scope.blue = $scope.get-percent newList, \blue
    $scope.red = $scope.get-percent newList, \red
    $scope.grey = 100 - $scope.green - $scope.blue - $scope.red

  console.log $location.path!

angular.module 'app', <[app.controllers]> ($locationProvider) ->
  $locationProvider.html5Mode true

<- $
$('.ui.dropdown').dropdown onChange: (v, t) -> console.log(v,t)
