cs = changesets.Changeset
dmp = new diff_match_patch()

angular.module 'app.controllers', <[ui.keypress angularLocalStorage ui.sortable monospaced.elastic truncate btford.socket-io debounce]>
.factory 'SocketIo', <[socketFactory]> ++ (socketFactory) -> return socketFactory!
.controller AppCtrl: <[$scope $location $window SocketIo $http]> ++ ($scope, $location, $window, SocketIo, $http) ->
  $scope.document-id = $location.path! - /^\//
  <- $http.get "/_/#{$scope.document-id}" .success _
  $scope{list,title,desc} = it

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
      new-item = title: $scope.newItem, status: \none, createdAt: Date.now!, uuid: uuid.v1!
      $scope.list.unshift new-item
      $scope.newItem = ""
      SocketIo.emit \op op: 'add item', item: new-item, doc: $scope.document-id

    toggle-status: (item, status) ->
      if item.status == status
        new-status = \none
      else
        new-status = status
      $scope.list[$scope.list.indexOf(item)] = item <<< status: new-status
      SocketIo.emit \op op: 'set status', target: item.uuid, status: new-status, doc: $scope.document-id

    set-search: (str) -> 
      $scope.search = str

    remove-item: (item) ->
      remove = $window.confirm("Remove Item: #{item.title} ?")
      $scope.list.splice $scope.list.indexOf(item), 1 if remove
      SocketIo.emit \op op: 'remove item', target: item.uuid, doc: $scope.document-id

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

  $scope.$watch 'list', (new-list) ->
    $scope.green = $scope.get-percent new-list, \green
    $scope.blue = $scope.get-percent new-list, \blue
    $scope.red = $scope.get-percent new-list, \red
    $scope.grey = 100 - $scope.green - $scope.blue - $scope.red
  , true

  console.log $scope.document-id

  $scope.$watch 'title' (new-val, old-val) ->
    if old-val != new-val
      console.log old-val, new-val
      ot = cs.from-diff dmp.diff_main(old-val, new-val)
      console.log ot.pack!
      SocketIo.emit \ot ot.pack!

angular.module 'app', <[app.controllers]> ($locationProvider) ->
  $locationProvider.html5Mode true

