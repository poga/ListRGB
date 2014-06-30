SimpleDoc = require './shared/simple-doc' .SimpleDoc
UserFeedback = require './shared/feedback' .UserFeedback
require! <[fs path express redis]>

redis = redis.createClient!
redis.on \error -> throw it

save-doc = (doc, id, cb) ->
  <- redis.set "doc:#id", JSON.stringify doc
  console.log "doc:#id saved"
  cb!

load-doc = (id, cb) ->
  console.log "loading doc:#id"
  err, value <- redis.get "doc:#id"
  if value
    cb new SimpleDoc JSON.parse value
  else
    cb new SimpleDoc!

load-feedback = (doc-id, uid, cb) ->
  console.log "loading feedback fb:#doc-id"
  err, value <- redis.get "fb:#doc-id"
  if value
    doc-fb = JSON.parse value
    if doc-fb[uid]
      cb UserFeedback.load doc-fb[uid]
    else
      cb new UserFeedback uid
  else
      cb new UserFeedback uid

load-feedback-all = (doc-id, cb) ->
  full = "feedback-#{doc-id}.json"
  console.log "loading feedback fb:#doc-id"
  err, value <- redis.get "fb:#doc-id"
  if value
    doc-fb = JSON.parse value
    fbs = []
    for uid, fb of doc-fb
      fbs.push UserFeedback.load fb
    cb fbs
  else
    cb []

save-feedback = (doc-id, feedback, cb) ->
  doc-fb-fn = "feedback-#{doc-id}.json"
  exists <- fs.exists doc-fb-fn
  if exists
    err, data <- fs.readFile doc-fb-fn, 'utf-8'
    doc-fb = JSON.parse data
    doc-fb[feedback.user-id] = feedback
    err <- fs.writeFile doc-fb-fn, JSON.stringify doc-fb, null, 4
    throw err if err
    console.log "#{doc-fb-fn} saved"
    cb!
  else
    doc-fb = {}
    doc-fb[feedback.user-id] = feedback
    err <- fs.writeFile doc-fb-fn, JSON.stringify doc-fb, null, 4
    throw err if err
    console.log "#{doc-fb-fn} saved"
    cb!

app = express!
app.use (require 'connect-livereload')( port: 35729 )
app.use express.static __dirname + "/_public"
app.get '/_/:fn/stats' (req, res) ->
  fbs <- UserFeedback.load-all-redis redis, req.param('fn')
  stats = doc-id: req.param('fn'), total:fbs.length
  for fb in fbs
    for eid, color of fb.feedbacks
      stats[eid] = green: 0, red: 0, blue: 0, none: 0 unless stats[eid]
      switch color
      | \green    => stats[eid].green++
      | \red      => stats[eid].red++
      | \blue     => stats[eid].blue++
      | otherwise => stats[eid].none++
  res.send stats
app.get '/_/:fn' (req, res) ->
  <- SimpleDoc.find-or-create-redis redis, req.param('fn')
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
      <- SimpleDoc.redis-add-entry redis, it.doc-id, it.entry
      socket.broadcast.emit \broadcast, op
    case 'remove entry'
      <- SimpleDoc.redis-remove-entry redis, it.doc-id, it.entry-uuid
      socket.broadcast.emit \broadcast, op
    case 'update entry'
      <- SimpleDoc.redis-set-entry redis, it.doc-id, it.entry-uuid, it.text
      socket.broadcast.emit \broadcast, op
    case 'update title'
      <- SimpleDoc.redis-set-title redis, it.doc-id, it.text
      socket.broadcast.emit \broadcast, op
    case 'update desc'
      <- SimpleDoc.redis-set-desc redis, it.doc-id, it.text
      socket.broadcast.emit \broadcast, op

http-server.listen 8000, ->
  console.log "Running on http://localhost:8000"

