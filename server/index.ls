Document = require './shared/document' .Document
UserFeedback = require './shared/feedback' .UserFeedback
require! <[fs path express redis]>

redis = redis.createClient!
redis.on \error -> throw it

app = express!
app.use (require 'connect-livereload')( port: 35729 )
app.use express.static __dirname + "/_public"
app.get '/_new' (req, res) ->
  res.redirect '/' + require('node-uuid').v1!replace(/-/g, '')
app.get '/_/:docid/stats' (req, res) ->
  fbs <- UserFeedback.load-all-redis redis, req.param('docid')
  doc <- Document.find-or-create-redis redis, req.param('docid')
  stats = doc-id: req.param('docid'), total:fbs.length
  for fb in fbs
    for e in doc.entries
      stats[e.uuid] = entry: e, green: 0, red: 0, blue: 0, none: 0 unless stats[e.uuid]
      switch fb.feedbacks[e.uuid]
      | \green    => stats[e.uuid].green++
      | \red      => stats[e.uuid].red++
      | \blue     => stats[e.uuid].blue++
      | otherwise => stats[e.uuid].none++
  res.send stats
app.get '/_/:docid' (req, res) ->
  <- Document.find-or-create-redis redis, req.param('docid')
  res.send it
app.get '/_/fb/:docid/:uid' (req, res) ->
  <- UserFeedback.load-doc-user-redis redis, req.param('docid'), req.param('uid')
  res.send it
app.all '/**' (req, res) ->
  res.sendfile __dirname + "/_public/app.html"
http-server = require \http .create-server app

io = require('socket.io')(http-server)

io.on \connection (socket) ->
  console.log socket.id, \connected
  #socket.emit \id, socket.id

  socket.on \register ->
    console.log socket.id, \register, it
    # TODO: leave registered doc-id
    <- socket.join it

  socket.on \op ->
    doc-id = socket.rooms.1 # rooms = [socket.id, doc.id]
    console.log socket.id, doc-id, \op, it
    op = it <<< doc-id: doc-id
    switch it.op
    case 'set feedback'
      old-color, new-color <- UserFeedback.redis-set redis, doc-id, it.uid, it.entry-id, it.color
      old-color = \none if old-color == null
      io.to(doc-id).emit \broadcast,(op <<< old: old-color)
    case 'add entry'
      <- Document.redis-add-entry redis, doc-id, it.entry
      socket.broadcast.to(doc-id).emit \broadcast, op
    case 'remove entry'
      <- Document.redis-remove-entry redis, doc-id, it.entry-uuid
      socket.broadcast.to(doc-id).emit \broadcast, op
    case 'update entry'
      <- Document.redis-set-entry redis, doc-id, it.entry-uuid, it.text
      socket.broadcast.to(doc-id).emit \broadcast, op
    case 'update title'
      <- Document.redis-set-title redis, doc-id, it.text
      socket.broadcast.to(doc-id).emit \broadcast, op
    case 'update desc'
      <- Document.redis-set-desc redis, doc-id, it.text
      socket.broadcast.to(doc-id).emit \broadcast, op
    case 'focus'
      socket.broadcast.to(doc-id).emit \broadcast, op
    case 'unfocus'
      socket.broadcast.to(doc-id).emit \broadcast, op

http-server.listen process.argv.2, ->
  console.log "Running on http://localhost:#{process.argv.2}"

