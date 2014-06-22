require! <[fs path express]>
cs = require('changesets').Changeset

app = express!
app.use (require 'connect-livereload')( port: 35729 )
app.use express.static __dirname + "/_public"
app.all '/**' (req, res) ->
  res.sendfile __dirname + "/_public/index.html"
http-server = require \http .create-server app

io = require('socket.io')(http-server)

io.on \connection (socket) ->
  console.log socket.id, \connected
  socket.emit \id, socket.id

  socket.on \op, ->
    console.log socket.id, it
    io.emit \op it

http-server.listen 8000, ->
  console.log "Running on http://localhost:8000"

