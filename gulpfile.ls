require! <[gulp path streamqueue gulp-concat gulp-nodemon]>
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

paths = do
  app:
    scripts: <[app/*.ls]>
    styles: <[app/styles/*.styl]>
    jade: <[app/templates/*.jade]>
  server:
    scripts: <[server/*.ls]>

gulp.task \server <[server:js]> ->
  gulp-nodemon script: 'index.js', ignore: <[app _public vendor]>

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

gulp.task \app:js ->
  gulp.src paths.app.scripts
    .pipe plumber!
    .pipe ls { +bare }
    .pipe gulp.dest "_public/js"

gulp.task 'server:js' ->
  gulp.src paths.server.scripts
    .pipe plumber!
    .pipe ls { +bare }
    .pipe gulp.dest "."

gulp.task \jade ->
  gulp.src paths.app.jade
    .pipe plumber!
    .pipe jade!
    .pipe gulp.dest "_public"

gulp.task \watch ->
  gulp.watch paths.app.styles, <[style]>
  gulp.watch paths.app.scripts, <[app:js]>
  gulp.watch paths.server.scripts, <[server:js]>
  gulp.watch paths.app.jade, <[jade]>

gulp.task \livereload ->
  lr.listen!
  gulp.watch '_public/js/**' .on \change, lr.changed
  gulp.watch '_public/*.html' .on \change, lr.changed
  gulp.watch '_public/css/**' .on \change, lr.changed

gulp.task \build <[bower style app:js server:js jade vendor:js assets]>

gulp.task \default <[build watch server livereload]>

gulp.task \prepublish <[build]>
