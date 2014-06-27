Doc = require './shared/doc' .Doc
Entry = require './shared/entry' .Entry
require! <[fs path express]>
cs = require('changesets').Changeset

save-doc = (doc-uuid, cb) ->
  err <- fs.writeFile "#{fns[doc-uuid]}.json", docs[doc-uuid].serialize!
  throw err if err
  console.log "#{doc-uuid} saved to #{fns[doc-uuid]}"
  cb!

docs = {}
fns = {}
app = express!
app.use (require 'connect-livereload')( port: 35729 )
app.use express.static __dirname + "/_public"
app.get '/_/:fn' (req, res) ->
  full-name = "#{req.param('fn')}.json"
  console.log \req-doc, full-name
  exists <- fs.exists full-name
  if exists
    err, data <- fs.readFile full-name, 'utf-8'
    doc = new Doc JSON.parse data
    docs[doc.uuid] = doc
    fns[doc.uuid] = req.param('fn')
    console.log "doc id #{doc.uuid} loaded"
    res.send JSON.parse data
  else
    doc = new Doc!
    docs[doc.uuid] = doc
    res.send docs[doc.uuid]
app.all '/**' (req, res) ->
  res.sendfile __dirname + "/_public/index.html"
http-server = require \http .create-server app

io = require('socket.io')(http-server)

io.on \connection (socket) ->
  console.log socket.id, \connected
  socket.emit \id, socket.id

  socket.on \ot, ->
    console.log socket.id, \ot, it
    # PULL ALL OTs in it.parent history, transformAgainst them one by one, then parent this ot to the last ot, push it into the history
    docs[it.doc].history[it.target] = [] unless docs[it.doc].history[it.target]
    ot = cs.unpack it.ot
    # XXX: get all ots after parent
    for o in docs[it.doc].history[it.target]
      ot = ot.transformAgainst o
    docs[it.doc][it.target] = ot.apply docs[it.doc][it.target]
    docs[it.doc].history[it.target].push ot
    console.log docs[it.doc][it.target]
    console.log docs[it.doc].history[it.target]
    <- save-doc it.doc
    socket.broadcast.emit \ot, it
    # XXX send ack

  socket.on \op ->
    console.log socket.id, \op, it
    switch it.op
    case 'set status'
      for item in docs[it.doc-uuid].list
        if item.uuid == it.target
          item.status = it.status
          break
      <- save-doc it.doc-uuid
    case 'add entry'
      console.log it.entry
      docs[it.doc-uuid].add-entry Entry.from-json(it.entry), it.tag
      <- save-doc it.doc-uuid
    case 'remove entry'
      docs[it.doc-uuid].remove-entry-by-uuid it.entry-uuid
      <- save-doc it.doc-uuid

http-server.listen 8000, ->
  console.log "Running on http://localhost:8000"

