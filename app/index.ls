cs = changesets.Changeset
dmp = new diff_match_patch()

angular.module 'app.controllers', <[ui.keypress angularLocalStorage ui.sortable monospaced.elastic truncate btford.socket-io]>
.factory 'SocketIo', <[socketFactory]> ++ (socketFactory) -> return socketFactory!
.controller AppCtrl: <[$scope storage $location $window SocketIo $timeout]> ++ ($scope, storage, $location, $window, SocketIo, $timeout) ->
  storage.bind $scope, \list, defaultValue: []
  storage.bind $scope, \desc, defaultValue: 'description here'
  storage.bind $scope, \title, defaultValue: 'title here'

  $scope.old-title = $scope.title

  $scope <<< do
    statuses: <[green blue red]>
    green: 0
    blue: 0
    red: 0
    grey: 0
    user: 'user'

    predicate: (x) -> $scope.list.indexOf(x)
    sorter: "none"

    parse-tags: (list) ->
      $scope.tags = []
      regex = /\s#(\S+)\s*?/g
      for x, i in list
        if x.title.match regex
          for tag in x.title.match(regex)
            $scope.tags.push tag unless $scope.tags.indexOf(tag) != -1

    add-item: ->
      $scope.list.unshift title: $scope.newItem, status: \none, createdAt: Date.now!, uuid: uuid.v1!
      $scope.newItem = ""

    set-status: (item, status) ->
      $scope.list[$scope.list.indexOf(item)] = if item.status == status
        item <<< status: \none
      else
        item <<< status: status

    set-search: (str) -> 
      $scope.search = str

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
        $scope.sortable-options = disabled: true
      case 'none'
        $scope.predicate = (x) -> $scope.list.indexOf(x)
        $scope.drag = {'display': 'inline-block'}
        $scope.sortable-options = disabled: false

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

  t = ->
    if $scope.old-title != $scope.title
      console.log $scope.old-title, $scope.title
      console.log cs.from-diff dmp.diff_main($scope.old-title, $scope.title)
      $scope.old-title = $scope.title
    $timeout t, 1000ms

  $timeout t, 1000ms

angular.module 'app', <[app.controllers]> ($locationProvider) ->
  $locationProvider.html5Mode true

