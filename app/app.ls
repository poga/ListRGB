Document = require '../shared/document' .Document
UserFeedback = require '../shared/feedback' .UserFeedback

angular.module 'app.controllers', <[ui.keypress monospaced.elastic truncate btford.socket-io debounce angularLocalStorage]>

.directive 'sparkline' ->
  return do
    restrict: \A
    require: \ngModel
    link: (scope, ele, attrs, ngModel) ->
      opts = type: attrs.type || 'line'
      scope.$watch attrs.ngModel,(-> render!), true
      scope.$watch attrs.opts,   (-> render!), true

      render = ->
        angular.extend opts, angular.fromJson attrs.opts if attrs.opts
        if angular.isString ngModel.$viewValue
          model = ngModel.$viewValue.replace(/(^,)|(,$)/g, "")
        else
          model = ngModel.$viewValue

        if angular.isArray model
          data = model
        else
          data = model.split ','

        $(ele).sparkline data, opts

.factory 'SocketIo', <[socketFactory]> ++ (socketFactory) -> return socketFactory!

.factory 'ListRGB', <[$http SocketIo]> ++ ($http, SocketIo) ->
  return do
    get: (id, cb) ->
      <- $http.get "_/#{id}" .success _
      cb new Document it
    colors: <[green blue red]>
    get-feedback: (doc-id, uid, cb) ->
      <- $http.get "_/fb/#{doc-id}/#{uid}" .success _
      cb UserFeedback.load it
    get-stats: (doc-id, cb) ->
      <- $http.get "_/#doc-id/stats" .success _
      cb it
    rand-user-color: ->
      <[#b58900 #cb4b16 #dc322f #d33682 #6c71c4 #268bd2 #2aa198 #859900]>[Math.floor(Math.random!*8)]

.controller AppCtrl: <[$scope $location $window SocketIo ListRGB storage]> ++ ($scope, $location, $window, SocketIo, ListRGB, storage) ->
  # connection status
  SocketIo.on \connect      ->
    SocketIo.emit \register, $scope.doc-id
    $scope.connected = yes
  SocketIo.on \error        -> $scope.connected = no
  SocketIo.on \disconnected -> $scope.connected = no
  SocketIo.on \reconnecting -> $scope.connected = no

  storage.bind $scope, 'uid', defaultValue: uuid.v1!
  storage.bind $scope, 'userColor', defaultValue: ListRGB.rand-user-color!
  storage.bind $scope, 'sorter', defaultValue: \none
  storage.bind $scope, 'customFilter', defaultValue: green: yes, red: yes, blue: yes, none: yes, text: ""

  $scope.doc-id = $location.path! - /^\//
  doc <- ListRGB.get $scope.doc-id
  fb <- ListRGB.get-feedback $scope.doc-id, $scope.uid
  stats <- ListRGB.get-stats $scope.doc-id
  # stats = { entry-id: [green, blue, red, none], ...}
  $scope.stats = {}
  for k, v of stats
    if k != "docId" and k != "total"
      $scope.stats[k] = [v.green, v.blue, v.red]
      if ($scope.stats[k].reduce (+) ) > 0
        $scope.stats[k].push 0
      else
        $scope.stats[k].push 1

  $scope <<< do
    colors: ListRGB.colors
    doc: doc
    fb: fb

    entry-style: {} # { entry-id: { background-color: color } }
    entry-focusing: {} # { user-id: { entry-id: , color }}

    default-predicate: (entry) -> $scope.doc.entries.indexOf(entry)
    predicate: $scope.default-predicate

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
      $scope.stats[entry.uuid] = [0, 0, 0, 1]
      SocketIo.emit \op op: 'add entry', entry: entry
      $scope.new-item = ""
      $scope.calculate-percentage $scope.doc.entries.length
      $scope.parse-tags!
      SocketIo.emit \op op: 'set feedback', uid: $scope.fb.user-id, entry-id: entry.uuid, color: \none

    remove-entry-by-uuid: (entry-uuid) ->
      remove = $window.confirm("Remove Item: #{$scope.doc.find-entry(entry-uuid).text} ?")
      if remove
        $scope.doc.remove-entry-by-uuid entry-uuid
        SocketIo.emit \op op: 'remove entry', entry-uuid: entry-uuid
        $scope.calculate-percentage $scope.doc.entries.length
        $scope.parse-tags!

    toggle-feedback: (entry, color) ->
      if $scope.fb.feedbacks[entry.uuid] != color
        $scope.fb.feedbacks[entry.uuid] = color
      else
        $scope.fb.feedbacks[entry.uuid] = \none
      $scope.calculate-percentage $scope.doc.entries.length
      SocketIo.emit \op op: 'set feedback', uid: $scope.fb.user-id, entry-id: entry.uuid, color: $scope.fb.feedbacks[entry.uuid]

    set-search: (str) ->
      if $scope.custom-filter.text == str
        $scope.custom-filter.text = ""
      else
        $scope.custom-filter.text = str

    set-sorter: (sorter) -> $scope.sorter = sorter

    sort: ->
      switch $scope.sorter
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
      case 'stats-green'
        $scope.predicate = []
          ..push (entry) ->
            -1 * $scope.stats[entry.uuid].0
          ..push $scope.default-predicate
      case 'stats-blue'
        $scope.predicate = []
          ..push (entry) ->
            -1 * $scope.stats[entry.uuid].1
          ..push $scope.default-predicate
      case 'stats-red'
        $scope.predicate = []
          ..push (entry) ->
            -1 * $scope.stats[entry.uuid].2
          ..push $scope.default-predicate
      case 'none'
        $scope.predicate = $scope.default-predicate

    calculate-percentage: ->
      $scope.percentage = $scope.fb.calculate-percentage $scope.doc.entries.length

    focus-entry: (user-id, entry-id, color) ->
      if color
        $scope.entry-focusing[user-id] = entry-id: entry-id, color: color
        $scope.entry-style[entry-id] = { 'border-color': color }
      else
        SocketIo.emit \op, op: \focus, entry-id: entry-id, color: $scope.user-color, user-id: $scope.uid

    unfocus-entry: (user-id, entry-id) ->
      delete $scope.entry-focusing[user-id]
      delete $scope.entry-style[entry-id]
      for uid, f of $scope.entry-focusing
        if f.entry-id == entry-id
          $scope.entry-style[entry-id] = { 'border-color': f.color }
          break
      SocketIo.emit \op, op: \unfocus, entry-id: entry-id, user-id: $scope.uid if user-id == $scope.uid

    parse-tags: ->
      $scope.tags = Document.parse-tags $scope.doc.entries.filter($scope.entry-filter $scope.custom-filter).map (.text)

  $scope.calculate-percentage $scope.doc.entries.length

  $scope.$watch 'sorter', $scope.sort

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
      $scope.parse-tags!
      SocketIo.emit \op op: 'update entry', entry-uuid: changed.uuid, text: changed.text
  ,true

  $scope.$watch 'doc.title' (new-title, old-title) ->
    if new-title != old-title
      SocketIo.emit \op op: 'update title', text: new-title

  $scope.$watch 'doc.desc' (new-desc, old-desc) ->
    if new-desc != old-desc
      SocketIo.emit \op op: 'update desc', text: new-desc

  $scope.$watch 'customFilter' ->
    $scope.parse-tags!
  , true

  SocketIo.emit \register, $scope.doc-id

  SocketIo.on \broadcast ->
    switch it.op
    case 'focus'
      $scope.focus-entry it.user-id, it.entry-id, it.color
    case 'unfocus'
      $scope.unfocus-entry it.user-id, it.entry-id
    case 'add entry'
      $scope.doc.add-entry it.entry
      $scope.stats[it.entry.uuid] = [0, 0, 0, 1]
      $scope.calculate-percentage $scope.doc.entries.length
      $scope.parse-tags!
    case 'remove entry'
      $scope.doc.remove-entry-by-uuid it.entry-uuid
      $scope.calculate-percentage $scope.doc.entries.length
      $scope.parse-tags!
    case 'update entry'
      $scope.suppress-watch-entries = true
      $scope.doc.update-entry it.entry-uuid, it.text
      $scope.parse-tags!
    case 'update title'
      $scope.doc.title = it.text
    case 'update desc'
      $scope.doc.desc = it.text
    case 'set feedback'
      color-idx = green: 0, blue: 1, red: 2, none: 3
      if $scope.stats[it.entry-id][color-idx[it.old]] > 0
        $scope.stats[it.entry-id][color-idx[it.old]]--
      if it.color != \none
        $scope.stats[it.entry-id][color-idx[it.color]]++
      if ($scope.stats[it.entry-id].reduce (+) ) == 0
        $scope.stats[it.entry-id][3] = 1

angular.module 'app', <[app.controllers]> ($locationProvider) ->
  $locationProvider.html5Mode true

