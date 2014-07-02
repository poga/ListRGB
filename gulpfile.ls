require! <[gulp path streamqueue gulp-concat gulp-nodemon browserify gulp-wait]>
gutil = require 'gulp-util'
stylus = require 'gulp-stylus'
nib = require \nib
ls = require 'gulp-livescript'
jade = require 'gulp-jade'
lr = require 'gulp-livereload'
plumber = require 'gulp-plumber'
bower = require 'gulp-bower'
bower-files = require 'gulp-bower-files'
filter = require 'gulp-filter'
source = require 'vinyl-source-stream'

paths = do
  app:
    scripts: <[app/*.ls]>
    styles: <[app/styles/*.styl]>
    jade: <[app/templates/*.jade]>
  server:
    scripts: <[server/*.ls]>
  shared:
    scripts: <[shared/*.ls]>

gulp.task \server <[server:js]> ->
  gulp-nodemon script: 'index.js', ignore: <[app _public vendor]>, args: [8000]

gulp.task \bower -> bower!

gulp.task \vendor:js <[bower]> ->
  f = bower-files!
    .pipe filter -> it.path == /\.js$/
  s = streamqueue {+objectMode}
    .done f, gulp.src 'app/vendor/scripts/*.js'
    .pipe gulp-concat 'vendor.js'
    .pipe gulp.dest '_public/js'

gulp.task \assets ->
  gulp.src "app/assets/**"
    .pipe gulp.dest '_public'

gulp.task \style ->
  gulp.src paths.app.styles
    .pipe plumber!
    .pipe stylus { +errors, use: [nib!]}
      .on 'error' -> @emit 'end'
    .pipe gulp.dest "_public/css"

gulp.task \app:js <[shared:js]> ->
  gulp.src paths.app.scripts
    .pipe plumber!
    .pipe ls { +bare }
    .pipe gulp.dest "app"
  browserify!
    .add "./app/index.js"
    .bundle!
    .pipe source("app.js")
    .pipe gulp-wait 1500ms     # if shared code is modified, we have to reload both server and client.
                               # and we don't want client to load anything before server is started.
    .pipe gulp.dest "_public/js"

gulp.task 'server:js' ->
  gulp.src paths.server.scripts
    .pipe plumber!
    .pipe ls { +bare }
    .pipe gulp.dest "."

gulp.task 'shared:js' ->
  gulp.src paths.shared.scripts
    .pipe plumber!
    .pipe ls { +bare }
    .pipe gulp.dest "shared"

gulp.task \jade ->
  gulp.src paths.app.jade
    .pipe plumber!
    .pipe jade!
    .pipe gulp.dest "_public"

gulp.task \watch ->
  gulp.watch paths.app.styles, <[style]>
  gulp.watch paths.app.scripts, <[app:js]>
  gulp.watch paths.app.jade, <[jade]>
  gulp.watch paths.server.scripts, <[server:js]>
  gulp.watch paths.shared.scripts, <[app:js]>

gulp.task \livereload ->
  lr.listen!
  gulp.watch '_public/js/**' .on \change, lr.changed
  gulp.watch '_public/*.html' .on \change, lr.changed
  gulp.watch '_public/css/**' .on \change, lr.changed

gulp.task \build <[bower style app:js server:js shared:js jade vendor:js assets]>

gulp.task \default <[build watch server livereload]>

gulp.task \prepublish <[build]>
