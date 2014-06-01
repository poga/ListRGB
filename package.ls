#!/usr/bin/env lsc -cj
author: 'Poga Po'
name: 'sopy'
description: 'collaborative list maker'
version: '0.0.1'
scripts:
  dev: "gulp --require LiveScript"
  prepublish: "gulp --require LiveScript prepublish"
dependencies:
  express: \*
devDependencies:
  jade: \*
  LiveScript: \*
  gulp: \*
  'gulp-util': \*
  'gulp-stylus': \*
  nib: \*
  'gulp-livescript': '~0.3.0'
  'gulp-jade': \*
  'gulp-livereload': \*
  'connect-livereload': \*
  'gulp-plumber': \*
