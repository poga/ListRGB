uuid = require 'node-uuid'

export class SimpleDoc
  (json) ->
    if json
      @{title, desc, entries} = json
    else
      @title = "untitled"
      @desc = "description"
      @entries = []

  add-entry-by-text: (text) ->
    e = uuid: uuid.v1!, text: text, createdAt: Date.now!
    @add-entry e
    return e

  add-entry: (e) ->
    @entries.unshift e

  update-entry: (uuid, text) ->
    e = @find-entry uuid
    e.text = text

  remove-entry-by-uuid: (uuid) ->
    var entry
    idx = -1
    for e, i in @entries
      if e.uuid == uuid
        idx := i
        entry := e
        break
    @entries.splice idx, 1

  find-entry: (uuid) ->
    for e in @entries
      if e.uuid == uuid
        return e

  toJSON: ->
    title: @title, desc: @desc, entries: @entries
