uuid = require 'node-uuid'
Edit = require './edit' .Edit
Snapshot = require './snapshot' .Snapshot
CS = require 'changesets' .Changeset

export class Entry
  @from-text = (text) ->
    e = new Entry(uuid.v1!)
    e.add-edit new Edit(CS.create!insert(text).end!pack!,
                        undefined,
                        uuid.v1!,
                        Date.now!)
    return e

  @from-json = (json) ->
    entry = new Entry json.uuid
    for e in json.edits
      entry.add-edit new Edit(e.cs, e.parent, e.uuid, e.createdAt)
    return entry

  (@uuid) ->
    @edits = []
  add-edit: (e) ->
    @edits.push e
  toJSON: ->
    uuid: @uuid, edits: @edits
  snapshot: ->
    text = ""
    for e in @edits
      text = e.apply text
    return new Snapshot(text, @uuid)
