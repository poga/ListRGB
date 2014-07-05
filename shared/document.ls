uuid = require 'node-uuid'
require! async

export class Document
  @default-config = do
    naming:
      green: \green
      blue: \blue
      red: \red
      none: \none
    icon:
      green: 'sign'
      blue: 'sign'
      red: 'sign'
      none: 'sign'

  @parse-tags = (texts) ->
    tags = []
    regex = /(^|\s)#(\S+)\s*?/gm
    for t in texts
      if t.match regex
        for tag in t.match regex
          tag = tag.replace /\s/, ''
          tags.push tag unless tags.indexOf(tag) != -1
    return tags

  @redis-set-config = (redis, doc-id, config, cb) ->
    <- redis.hset "doc:#doc-id:config:naming", "green" config.naming.green
    <- redis.hset "doc:#doc-id:config:naming", "blue" config.naming.blue
    <- redis.hset "doc:#doc-id:config:naming", "red" config.naming.red
    <- redis.hset "doc:#doc-id:config:naming", "none" config.naming.none
    <- redis.hset "doc:#doc-id:config:icon", "green" config.icon.green
    <- redis.hset "doc:#doc-id:config:icon", "blue" config.icon.blue
    <- redis.hset "doc:#doc-id:config:icon", "red" config.icon.red
    <- redis.hset "doc:#doc-id:config:icon", "none" config.icon.none
    cb!

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
    inits.push (cb) -> # init title
      redis.setnx "doc:#doc-id:title", "untitled", cb
    inits.push (cb) -> # init description
      redis.setnx "doc:#doc-id:desc", "default description", cb
    inits.push (cb) -> # init config
      <- redis.hsetnx "doc:#doc-id:config:naming", "green", Document.default-config.naming.green
      <- redis.hsetnx "doc:#doc-id:config:naming", "blue", Document.default-config.naming.blue
      <- redis.hsetnx "doc:#doc-id:config:naming", "red", Document.default-config.naming.red
      <- redis.hsetnx "doc:#doc-id:config:naming", "none", Document.default-config.naming.none
      <- redis.hsetnx "doc:#doc-id:config:icon", "green", Document.default-config.icon.green
      <- redis.hsetnx "doc:#doc-id:config:icon", "blue", Document.default-config.icon.blue
      <- redis.hsetnx "doc:#doc-id:config:icon", "red", Document.default-config.icon.red
      <- redis.hsetnx "doc:#doc-id:config:icon", "none", Document.default-config.icon.none
      cb!
    <- async.parallel inits

    doc.config = naming: {}, icon: {}

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
    loaders.push (cb) ->
      err, config <- redis.hgetall "doc:#doc-id:config:naming"
      doc.config.naming = config
      cb!
    loaders.push (cb) ->
      err, config <- redis.hgetall "doc:#doc-id:config:icon"
      doc.config.icon = config
      cb!
    <- async.parallel loaders
    cb doc

  (json) ->
    if json
      @{title, desc, entries, config} = json
    else
      @title = "untitled"
      @desc = "description"
      @entries = []
      @config = Document.default-config
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
    title: @title, desc: @desc, entries: @entries, config: @config

  set-config: (c) ->
    @config = c
