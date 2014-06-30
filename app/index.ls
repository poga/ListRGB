cs = changesets.Changeset
dmp = new diff_match_patch()
SimpleDoc = require '../shared/simple-doc' .SimpleDoc
UserFeedback = require '../shared/feedback' .UserFeedback

angular.module 'app.controllers', <[ui.keypress monospaced.elastic truncate btford.socket-io debounce angularLocalStorage]>

.factory 'SocketIo', <[socketFactory]> ++ (socketFactory) -> return socketFactory!

.factory 'ListRGB', <[$http SocketIo]> ++ ($http, SocketIo) ->
  return do
    get: (id, cb) ->
      <- $http.get "_/#{id}" .success _
      cb new SimpleDoc it
    colors: <[green blue red]>
    get-feedback: (doc-id, uid, cb) ->
      <- $http.get "_/fb/#{doc-id}/#{uid}" .success _
      cb UserFeedback.load it

.controller AppCtrl: <[$scope $location $window SocketIo ListRGB storage]> ++ ($scope, $location, $window, SocketIo, ListRGB, storage) ->
  # connection status
  SocketIo.on \connect      -> $scope.connected = yes
  SocketIo.on \error        -> $scope.connected = no
  SocketIo.on \disconnected -> $scope.connected = no
  SocketIo.on \reconnecting -> $scope.connected = no

  storage.bind $scope, 'uid', defaultValue: uuid.v1!

  $scope.doc-id = $location.path! - /^\//
  doc <- ListRGB.get $scope.doc-id
  fb <- ListRGB.get-feedback $scope.doc-id, $scope.uid

  $scope <<< do
    colors: ListRGB.colors
    doc: doc
    fb: fb
    
    default-predicate: (entry) -> $scope.doc.entries.indexOf(entry)
    predicate: $scope.default-predicate
    sorter: "none"

    custom-filter: green: yes, red: yes, blue: yes, none: yes, text: ""

    entry-filter: (custom-filter)->
      return (e) ->
        res = false
        if (custom-filter[$scope.fb.feedbacks[e.uuid]] or
          ($scope.fb.feedbacks[e.uuid] == undefined and custom-filter.none)) and
          e.text.indexOf(custom-filter.text) != -1
          res = true

        return res

    add-entry: ->
      entry = $scope.doc.add-entry-by-text $scope.new-item
      SocketIo.emit \op op: 'add entry', doc-id: $scope.doc-id, entry: entry
      $scope.new-item = ""
      $scope.calculate-percentage $scope.doc.entries.length

    remove-entry-by-uuid: (entry-uuid) ->
      remove = $window.confirm("Remove Item: #{$scope.doc.find-entry(entry-uuid).text} ?")
      if remove
        $scope.doc.remove-entry-by-uuid entry-uuid
        SocketIo.emit \op op: 'remove entry', entry-uuid: entry-uuid, doc-id: $scope.doc-id
        $scope.calculate-percentage $scope.doc.entries.length

    toggle-feedback: (entry, color) ->
      if $scope.fb.feedbacks[entry.uuid] != color
        $scope.fb.feedbacks[entry.uuid] = color
      else
        $scope.fb.feedbacks[entry.uuid] = \none
      $scope.calculate-percentage $scope.doc.entries.length
      SocketIo.emit \op op: 'set feedback', uid: $scope.fb.user-id, entry-id: entry.uuid, color: $scope.fb.feedbacks[entry.uuid], doc-id: $scope.doc-id

    set-search: (str) ->
      if $scope.custom-filter.text == str
        $scope.custom-filter.text = ""
      else
        $scope.custom-filter.text = str

    sort-by: (sorter) ->
      $scope.sorter = sorter
      switch sorter
      case 'color'
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

    calculate-percentage: ->
      $scope.percentage = $scope.fb.calculate-percentage $scope.doc.entries.length

  $scope.calculate-percentage $scope.doc.entries.length

  $scope.$watch 'doc.entries' (new-entries, old-entries) ->
    if $scope.suppress-watch-entries
      $scope.suppress-watch-entries = false
      return
    var changed
    for n in new-entries
      for o in old-entries
        if n.uuid == o.uuid
          changed := n if n.text != o.text
          break
    if changed
      $scope.doc.parse-tags!
      SocketIo.emit \op op: 'update entry', entry-uuid: changed.uuid, doc-id: $scope.doc-id, text: changed.text
  ,true

  $scope.$watch 'doc.title' (new-title, old-title) ->
    if new-title != old-title
      SocketIo.emit \op op: 'update title', doc-id: $scope.doc-id, text: new-title

  $scope.$watch 'doc.desc' (new-desc, old-desc) ->
    if new-desc != old-desc
      SocketIo.emit \op op: 'update desc', doc-id: $scope.doc-id, text: new-desc

  SocketIo.on \broadcast ->
    switch it.op
    case 'add entry'
      $scope.doc.add-entry it.entry
    case 'remove entry'
      $scope.doc.remove-entry-by-uuid it.entry-uuid
    case 'update entry'
      $scope.suppress-watch-entries = true
      $scope.doc.update-entry it.entry-uuid, it.text
    case 'update title'
      $scope.doc.title = it.text
    case 'update desc'
      $scope.doc.desc = it.text

angular.module 'app', <[app.controllers]> ($locationProvider) ->
  $locationProvider.html5Mode true

