uuid = require 'node-uuid'
Edit = require './edit' .Edit
CS = require 'changesets' .Changeset
Entry = require './entry' .Entry

export class Doc
  @colors = <[green blue red]>

  (json) ->
    if json
      @{entry-tags, uuid} = json
      @entries = []
      for entry in json.entries
        new-entry = new Entry(entry.uuid)
        for e in entry.edits
          new-entry.edits.push new Edit(e.cs, e.parentId, e.uuid, e.createdAt)
        @entries.push new-entry
    else
      @entry-tags = []
      @entries = []
      @uuid = uuid.v1!
    @build-snapshots!
    #@parse-tags!
    #@calculate-all-percentage!
  
  build-snapshots: ->
    @snapshots = []
    for e in @entries
      @snapshots.push e.snapshot!

  add-entry: (entry, tag) ->
    @entries.unshift entry
    @entry-tags.push name: tag, entry-id: entry.uuid if tag
    @snapshots.unshift entry.snapshot!

  remove-entry-by-uuid: (entry-uuid) ->
    idx-to-remove = -1
    for e,i in @entries
      if e.uuid == entry-uuid
        idx-to-remove := i
        break
    if idx-to-remove != -1
      @entries.splice idx-to-remove, 1
      s-id = -1
      for s, i in @snapshots
        if s.entry-uuid == entry-uuid
          s-id = i
          break
      @snapshots.splice s-id, 1

  serialize: ->
    json = entry-tags: @entry-tags, uuid: @uuid, entries: []
    for e in @entries
      json.entries.push e
    return JSON.stringify(json, null, 4)

  parse-tags: ->
    # XXX: need rewrite
    @tags = []
    regex = /\s#(\S+)\s*?/g
    for x, i in @objects
      if x.snapshot.match regex
        for tag in x.snapshot.match(regex)
          @tags.push tag unless @tags.indexOf(tag) != -1

  calculate-all-percentage: ->
    # XXX: extract
    @percentage = {}
    for color in <[green red blue]>
      @percentage[color] = @calculate-percentage color
    @percentage[\grey] = 100 - @percentage.green - @percentage.red - @percentage.blue

  calculate-percentage: (color) ->
    # XXX: extract
    return 0 if @objects.length == 0
    @objects.filter((o) -> o.status == color).length * 100.0 / @objects.length

