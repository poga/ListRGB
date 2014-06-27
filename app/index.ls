cs = changesets.Changeset
dmp = new diff_match_patch()
SimpleDoc = require '../shared/simple-doc' .SimpleDoc
Feedback = require '../shared/feedback' .Feedback

angular.module 'app.controllers', <[ui.keypress monospaced.elastic truncate btford.socket-io debounce angularLocalStorage]>

.factory 'SocketIo', <[socketFactory]> ++ (socketFactory) -> return socketFactory!

.factory 'ListRGB', <[$http SocketIo]> ++ ($http, SocketIo) ->
  return do
    get: (id, cb) ->
      <- $http.get "_/#{id}" .success _
      cb new SimpleDoc it
    colors: <[green blue red]>
    get-feedback: (doc-id, uid, cb) ->
      console.log \get, "_/fb/#{doc-id}/#{uid}"
      <- $http.get "_/fb/#{doc-id}/#{uid}" .success _
      console.log it
      cb Feedback.load-json it
.controller AppCtrl: <[$scope $location $window SocketIo ListRGB storage]> ++ ($scope, $location, $window, SocketIo, ListRGB, storage) ->
  storage.bind $scope, 'uid', defaultValue: uuid.v1!

  $scope.doc-id = $location.path! - /^\//
  console.log $scope.doc-id
  doc <- ListRGB.get $scope.doc-id
  console.log doc
  fb <- ListRGB.get-feedback $scope.doc-id, $scope.uid
  console.log fb

  $scope <<< do
    colors: ListRGB.colors
    doc: doc
    fb: fb
    percentage: doc.percentage
    user: 'user'

    default-predicate: (entry) -> $scope.doc.entries.indexOf(entry)
    predicate: $scope.default-predicate
    sorter: "none"

    add-entry: ->
      entry = $scope.doc.add-entry-by-text $scope.new-item
      SocketIo.emit \op op: 'add entry', doc-id: $scope.doc-id, entry: entry
      $scope.new-item = ""

    remove-entry-by-uuid: (entry-uuid) ->
      remove = $window.confirm("Remove Item: #{$scope.doc.find-entry(entry-uuid).text} ?")
      $scope.doc.remove-entry-by-uuid entry-uuid if remove
      SocketIo.emit \op op: 'remove entry', entry-uuid: entry-uuid, doc-id: $scope.doc-id

    toggle-feedback: (entry, color) ->
      if $scope.fb.feedbacks[entry.uuid] != color
        $scope.fb.feedbacks[entry.uuid] = color
      else
        $scope.fb.feedbacks[entry.uuid] = \none
      SocketIo.emit \op op: 'set feedback', uid: $scope.fb.user-id, entry-id: entry.uuid, color: $scope.fb.feedbacks[entry.uuid], doc-id: $scope.doc-id

    set-search: (str) ->
      if $scope.search == str
        $scope.search = ""
      else
        $scope.search = str

    sort-by: (sorter) ->
      $scope.sorter = sorter
      switch sorter
      case 'status'
        $scope.predicate = []
          ..push (entry) ->
            switch $scope.fb.feedbacks[entry.uuid]
            | \none => 0
            | undefined => 0
            | \green => 1
            | \blue => 2
            | \red => 3
          ..push $scope.default-predicate
      case 'none'
        $scope.predicate = $scope.default-predicate

  $scope.$watch 'doc.entries' (new-entries, old-entries) ->
    # XXX: find a better way to do this
    var changed
    for n,i in new-entries
      if n.text != old-entries[i].text
        changed := n
        break
    if changed
      $scope.doc.parse-tags!
      SocketIo.emit \op op: 'update entry', entry-uuid: changed.uuid, doc-id: $scope.doc-id, text: changed.text
  ,true

angular.module 'app', <[app.controllers]> ($locationProvider) ->
  $locationProvider.html5Mode true

