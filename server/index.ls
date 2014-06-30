Document = require './shared/document' .Document
UserFeedback = require './shared/feedback' .UserFeedback
require! <[fs path express redis]>

redis = redis.createClient!
redis.on \error -> throw it

app = express!
app.use (require 'connect-livereload')( port: 35729 )
app.use express.static __dirname + "/_public"
app.get '/_/:fn/stats' (req, res) ->
  fbs <- UserFeedback.load-all-redis redis, req.param('fn')
  doc <- Document.find-or-create-redis redis, req.param('fn')
  stats = doc-id: req.param('fn'), total:fbs.length
  for fb in fbs
    for e in doc.entries
      stats[e.uuid] = entry: e, green: 0, red: 0, blue: 0, none: 0 unless stats[e.uuid]
      switch fb.feedbacks[e.uuid]
      | \green    => stats[e.uuid].green++
      | \red      => stats[e.uuid].red++
      | \blue     => stats[e.uuid].blue++
      | otherwise => stats[e.uuid].none++
  res.send stats
app.get '/_/:fn' (req, res) ->
  <- Document.find-or-create-redis redis, req.param('fn')
  res.send it
app.get '/_/fb/:docid/:uid' (req, res) ->
  <- UserFeedback.load-doc-user-redis redis, req.param('docid'), req.param('uid')
  res.send it
app.all '/**' (req, res) ->
  res.sendfile __dirname + "/_public/index.html"
http-server = require \http .create-server app

io = require('socket.io')(http-server)

io.on \connection (socket) ->
  console.log socket.id, \connected
  socket.emit \id, socket.id

  socket.on \op ->
    console.log socket.id, \op, it
    op = it
    switch it.op
    case 'set feedback'
      <- UserFeedback.redis-set redis, it.doc-id, it.uid, it.entry-id, it.color
    case 'add entry'
      <- Document.redis-add-entry redis, it.doc-id, it.entry
      socket.broadcast.emit \broadcast, op
    case 'remove entry'
      <- Document.redis-remove-entry redis, it.doc-id, it.entry-uuid
      socket.broadcast.emit \broadcast, op
    case 'update entry'
      <- Document.redis-set-entry redis, it.doc-id, it.entry-uuid, it.text
      socket.broadcast.emit \broadcast, op
    case 'update title'
      <- Document.redis-set-title redis, it.doc-id, it.text
      socket.broadcast.emit \broadcast, op
    case 'update desc'
      <- Document.redis-set-desc redis, it.doc-id, it.text
      socket.broadcast.emit \broadcast, op

http-server.listen 8000, ->
  console.log "Running on http://localhost:8000"

