require! <[fs path express]>
cs = require('changesets').Changeset

save-doc = (doc, cb) ->
  err <- fs.writeFile fn, JSON.stringify(doc)
  throw err if err
  console.log 'doc saved'
  cb!

var doc, fn
app = express!
app.use (require 'connect-livereload')( port: 35729 )
app.use express.static __dirname + "/_public"
app.get '/_/:fn' (req, res) ->
  fn := "#{req.param('fn')}.json"
  console.log \req-doc, fn
  exists <- fs.exists fn
  if exists
    err, data <- fs.readFile fn, 'utf-8'
    doc := JSON.parse data
    res.send doc
  else
    doc := title: "untitled", desc: "put description here", list: []
    res.send doc
app.all '/**' (req, res) ->
  res.sendfile __dirname + "/_public/index.html"
http-server = require \http .create-server app

io = require('socket.io')(http-server)

io.on \connection (socket) ->
  console.log socket.id, \connected
  socket.emit \id, socket.id

  socket.on \ot, ->
    console.log socket.id, \ot, it
    io.emit \ot it

  socket.on \op ->
    console.log socket.id, \op, it
    switch it.op
    case 'set status'
      for item in doc.list
        if item.uuid == it.target
          item.status = it.status
          break
      <- save-doc doc
    case 'add item'
      doc.list.unshift it.item
      <- save-doc doc
    case 'remove item'
      item-to-remove = doc.list.filter((x) -> x.uuid == it.target).0
      idx-to-remove = doc.list.indexOf(item-to-remove)
      console.log idx-to-remove
      if item-to-remove != -1
        removed = doc.list.splice doc.list.indexOf(item-to-remove), 1
        console.log removed
        <- save-doc doc

http-server.listen 8000, ->
  console.log "Running on http://localhost:8000"

