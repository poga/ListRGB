uuid = require 'node-uuid'
require! async

export class Document
  @parse-tags = (texts) ->
    tags = []
    regex = /(^|\s)#(\S+)\s*?/gm
    for t in texts
      if t.match regex
        for tag in t.match regex
          tag = tag.replace /\s/, ''
          tags.push tag unless tags.indexOf(tag) != -1
    return tags

  @redis-set-title = (redis, doc-id, title, cb) ->
    err, v <- redis.set "doc:#doc-id:title", title
    cb!

  @redis-set-desc = (redis, doc-id, desc, cb) ->
    err, v <- redis.set "doc:#doc-id:desc", desc
    cb!

  @redis-set-entry = (redis, doc-id, entry-id, text, cb) ->
    err, v <- redis.hset "doc:#doc-id:entries:#entry-id", "text", text
    cb!

  @redis-add-entry-by-text = (redis, doc-id, text, cb) ->
    <- Document.redis-add-entry redis, doc-id, uuid: uuid.v1!, text: text, createdAt: Date.now!
    cb!

  @redis-add-entry = (redis, doc-id, entry, cb) ->
    entry-id = entry.uuid
    err, v <- redis.hset "doc:#doc-id:entries:#entry-id", "uuid" entry.uuid
    err, v <- redis.hset "doc:#doc-id:entries:#entry-id", "text" entry.text
    err, v <- redis.hset "doc:#doc-id:entries:#entry-id", "createdAt" entry.createdAt
    err, v <- redis.lpush "doc:#doc-id:entries", entry-id
    cb!

  @redis-remove-entry = (redis, doc-id, entry-id, cb) ->
    err, v <- redis.del "doc:#doc-id:entries:#entry-id"
    err, v <- redis.lrem "doc:#doc-id:entries", 0, entry-id
    cb!

  @find-or-create-redis = (redis, doc-id, cb) ->
    doc = new Document!
    inits = []
    inits.push (cb) ->
      redis.setnx "doc:#doc-id:title", "untitled", cb
    inits.push (cb) ->
      redis.setnx "doc:#doc-id:desc", "default description", cb
    <- async.parallel inits

    loaders = []
    loaders.push (cb) ->
      err, v <- redis.get "doc:#doc-id:title"
      doc.title = v
      cb!
    loaders.push (cb) ->
      err, v <- redis.get "doc:#doc-id:desc"
      doc.desc = v
      cb!
    loaders.push (cb) ->
      err, eids <- redis.lrange("doc:#doc-id:entries", 0, -1)
      throw err if err
      async.map eids, (eid, cb) ->
        err, v <- redis.hgetall "doc:#doc-id:entries:#eid"
        cb err, v
      , (err, entries) ->
        doc.entries = entries
        cb!
    <- async.parallel loaders
    cb doc

  (json) ->
    if json
      @{title, desc, entries} = json
    else
      @title = "untitled"
      @desc = "description"
      @entries = []
    @parse-tags!

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

  parse-tags: ->
    @tags = Document.parse-tags @entries.map (.text)

  toJSON: ->
    title: @title, desc: @desc, entries: @entries
