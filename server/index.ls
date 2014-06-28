SimpleDoc = require './shared/simple-doc' .SimpleDoc
Feedback = require './shared/feedback' .Feedback
require! <[fs path express]>

save-doc = (doc, fn, cb) ->
  err <- fs.writeFile "#{fn}.json", JSON.stringify doc, null, 4
  throw err if err
  console.log "#{fn}.json saved"
  cb!

load-doc = (fn, cb) ->
  full-name = "#{fn}.json"
  console.log "loading doc #full-name"
  exists <- fs.exists full-name
  if exists
    err, data <- fs.readFile full-name, 'utf-8'
    doc = new SimpleDoc JSON.parse data
    cb doc
  else
    doc = new SimpleDoc!
    cb doc

load-feedback = (doc-id, uid, cb) ->
  full = "feedback-#{doc-id}.json"
  console.log "loading feedback #full"
  exists <- fs.exists full
  if exists
    err, data <- fs.readFile full, 'utf-8'
    doc-fb = JSON.parse data
    if doc-fb[uid]
      cb Feedback.load-json doc-fb[uid]
    else
      cb new Feedback uid
  else
    fb = new Feedback uid
    cb fb

load-feedback-all = (doc-id, cb) ->
  full = "feedback-#{doc-id}.json"
  console.log "loading feedback #full"
  exists <- fs.exists full
  if exists
    err, data <- fs.readFile full, 'utf-8'
    doc-fb = JSON.parse data
    res = []
    for uid, fb of doc-fb
      res.push Feedback.load-json fb
    cb res
  else
    cb undefined

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
  fn = req.param('fn')
  fbs <- load-feedback-all fn
  console.log fbs
  stats = doc-id: fn, total:fbs.length
  for fb in fbs
    for eid, color of fb.feedbacks
      stats[eid] = green: 0, red: 0, blue: 0, none: 0 unless stats[eid]
      console.log eid, color
      switch color
      | \green    => stats[eid].green++
      | \red      => stats[eid].red++
      | \blue     => stats[eid].blue++
      | otherwise => stats[eid].none++
  res.send stats
app.get '/_/:fn' (req, res) ->
  fn = req.param('fn')
  <- load-doc fn
  res.send it
app.get '/_/fb/:docid/:uid' (req, res) ->
  <- load-feedback req.param('docid'), req.param('uid')
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
      fb <- load-feedback it.doc-id, it.uid
      fb.set it.entry-id, it.color
      <- save-feedback it.doc-id, fb
    case 'add entry'
      doc <- load-doc it.doc-id
      doc.add-entry it.entry
      <- save-doc doc, it.doc-id
      socket.broadcast.emit \broadcast, op
    case 'remove entry'
      doc <- load-doc it.doc-id
      doc.remove-entry-by-uuid it.entry-uuid
      <- save-doc doc, it.doc-id
      socket.broadcast.emit \broadcast, op
    case 'update entry'
      doc <- load-doc it.doc-id
      doc.update-entry it.entry-uuid, it.text
      <- save-doc doc, it.doc-id
      socket.broadcast.emit \broadcast, op
    case 'update title'
      doc <- load-doc it.doc-id
      doc.title = it.text
      <- save-doc doc, it.doc-id
      socket.broadcast.emit \broadcast, op
    case 'update desc'
      doc <- load-doc it.doc-id
      doc.desc = it.text
      <- save-doc doc, it.doc-id
      socket.broadcast.emit \broadcast, op

http-server.listen 8000, ->
  console.log "Running on http://localhost:8000"

