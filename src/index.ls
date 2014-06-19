setup-dropdown = ->
  $('.ui.dropdown').dropdown onChange: (v, t) ->
    angular.element($('body')).scope!setCategory(v, $(@).data('item-uuid'))

angular.module 'app.controllers', <[ui.keypress angularLocalStorage ui.sortable monospaced.elastic truncate]>
.controller AppCtrl: <[$scope storage $location $window]> ++ ($scope, storage, $location, $window) ->
  storage.bind $scope, \list, defaultValue: []
  storage.bind $scope, \categories, defaultValue: []

  $scope <<< do
    statuses: <[green blue red]>
    green: 0
    blue: 0
    red: 0
    grey: 0

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

    add-category: !->
      $('.ui.dropdown').dropdown('destroy')
      $scope.categories.push $scope.newCategory
      $scope.newCategory = ""
      setTimeout setup-dropdown, 1ms

    set-category: (c, uuid) ->
      for x in $scope.list
        if x.uuid == uuid
          x.c = c
          return

    set-status: (item, status) ->
      $scope.list[$scope.list.indexOf(item)] = if item.status == status
        item <<< status: \none
      else
        item <<< status: status

    set-search: (str) -> 
      $scope.search = str

    set-search-category: (c) ->
      $scope.search = {c: c}

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
      case 'category'
        $scope.predicate = []
          ..push (x) ->
            $scope.categories.indexOf x.c
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
setup-dropdown!
