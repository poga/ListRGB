cs = changesets.Changeset
dmp = new diff_match_patch()
Doc = require '../shared/document' .Doc
Edit = require '../shared/edit' .Edit
Entry = require '../shared/entry' .Entry

angular.module 'app.controllers', <[ui.keypress monospaced.elastic truncate btford.socket-io debounce]>

.factory 'SocketIo', <[socketFactory]> ++ (socketFactory) -> return socketFactory!

.factory 'ListRGB', <[$http SocketIo]> ++ ($http, SocketIo) ->
  return do
    get: (id, cb) ->
      <- $http.get "_/#{id}" .success _
      cb new Doc(it)
    colors: Doc.colors

.controller AppCtrl: <[$scope $location $window SocketIo ListRGB]> ++ ($scope, $location, $window, SocketIo, ListRGB) ->
  $scope.doc-id = $location.path! - /^\//
  console.log $scope.doc-id
  doc <- ListRGB.get $scope.doc-id
  console.log doc

  $scope <<< do
    colors: ListRGB.colors
    doc: doc
    percentage: doc.percentage
    user: 'user'
    tags: doc.tags

    default-predicate: (x) -> $scope.doc.objects.indexOf(x)
    predicate: $scope.default-predicate
    sorter: "none"

    get-percent: (list, status) ->
      return 0 if list.length == 0
      list.filter((x) -> x.status == status).length * 100.0 / list.length

    add-entry: ->
      entry = Entry.from-text $scope.new-item
      console.log entry
      $scope.doc.add-entry(entry)
      SocketIo.emit \op op: 'add entry', doc-uuid: doc.uuid, entry: entry
      $scope.new-item = ""

    remove-entry-by-uuid: (entry-uuid) ->
      var entry
      for e in $scope.doc.entries
        if e.uuid == entry-uuid
          entry = e
          break
      remove = $window.confirm("Remove Item: #{entry.snapshot!text} ?")
      $scope.doc.remove-entry-by-uuid entry-uuid if remove
      SocketIo.emit \op op: 'remove entry', entry-uuid: entry-uuid, doc-uuid: doc.uuid

    toggle-status: (item, status) ->
      ...

    set-search: (str) ->
      $scope.search = str

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
          ..push $scope.default-predicate
      case 'none'
        $scope.predicate = $scope.default-predicate

  $scope.$watch 'title' (new-val, old-val) ->
    if old-val != new-val
      console.log old-val, new-val
      ot = cs.from-diff dmp.diff_main(old-val, new-val)
      console.log ot.pack!
      if $scope.history[\title].length == 0 # there is no history for this object
        SocketIo.emit \ot ot: ot.pack!, target: \title, doc-uuid: $scope.doc.uuid, uuid: uuid.v1!
# XXX maintain a history in client side
# XXX handle ack

angular.module 'app', <[app.controllers]> ($locationProvider) ->
  $locationProvider.html5Mode true

