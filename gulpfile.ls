require! <[gulp path]>
gutil = require 'gulp-util'
stylus = require 'gulp-stylus'
nib = require \nib
ls = require 'gulp-livescript'
jade = require 'gulp-jade'
lr = require 'gulp-livereload'
plumber = require 'gulp-plumber'
bower = require 'gulp-bower'

paths = do
  scripts: <[src/*.ls]>
  styles: <[styles/*.styl]>
  jade: <[templates/*.jade]>

gulp.task \server ->
  require! express
  app = express!
  app.use (require 'connect-livereload')( port: 35729 )
  app.use express.static path.resolve '.'
  app.all '/**' (req, res) ->
    res.sendfile __dirname + "/index.html"
  http-server = require \http .create-server app
  http-server.listen 8000, ->
    gutil.log "Running on " + gutil.colors.bold.inverse "http://localhost:8000"

gulp.task \bower -> bower!

gulp.task \style ->
  gulp.src paths.styles
    .pipe plumber!
    .pipe stylus { +errors, use: [nib!]}
      .on 'error' -> @emit 'end'
    .pipe gulp.dest "css"

gulp.task \ls ->
  gulp.src paths.scripts
    .pipe plumber!
    .pipe ls { +bare }
    .pipe gulp.dest "lib"

gulp.task \jade ->
  gulp.src paths.jade
    .pipe plumber!
    .pipe jade!
    .pipe gulp.dest "."

gulp.task \watch ->
  gulp.watch paths.styles, <[style]>
  gulp.watch paths.scripts, <[ls]>
  gulp.watch paths.jade, <[jade]>

gulp.task \livereload ->
  server = lr!
  reload = (path) ->
    server.changed path
  gulp.watch paths.styles .on \change, reload
  gulp.watch paths.scripts .on \change, reload
  gulp.watch paths.jade .on \change, reload

gulp.task \build <[bower style ls jade]>

gulp.task \default <[build watch livereload server]>

gulp.task \prepublish <[build]>
