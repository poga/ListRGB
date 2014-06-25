require! <[fs path express]>
cs = require('changesets').Changeset

save-doc = (doc, cb) ->
  err <- fs.writeFile "#doc.json", JSON.stringify(docs[doc])
  throw err if err
  console.log 'doc saved'
  cb!

docs = {}
app = express!
app.use (require 'connect-livereload')( port: 35729 )
app.use express.static __dirname + "/_public"
app.get '/_/:doc' (req, res) ->
  doc = req.param('doc')
  fn = "#{req.param('doc')}.json"
  console.log \req-doc, fn
  exists <- fs.exists fn
  if exists
    err, data <- fs.readFile fn, 'utf-8'
    docs[doc] = JSON.parse data
    res.send docs[doc]
  else
    docs[doc] = title: "untitled", desc: "put description here", list: []
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
      for item in docs[doc].list
        if item.uuid == it.target
          item.status = it.status
          break
      <- save-doc it.doc
    case 'add item'
      docs[doc].list.unshift it.item
      <- save-doc it.doc
    case 'remove item'
      item-to-remove = docs[it.doc].list.filter((x) -> x.uuid == it.target).0
      idx-to-remove = docs[it.doc].list.indexOf(item-to-remove)
      console.log idx-to-remove
      if item-to-remove != -1
        removed = docs[it.doc].list.splice docs[it.doc].list.indexOf(item-to-remove), 1
        console.log removed
        <- save-doc it.doc

http-server.listen 8000, ->
  console.log "Running on http://localhost:8000"

