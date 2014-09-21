gulp = require 'gulp'
gp = do require "gulp-load-plugins"

streamqueue = require 'streamqueue'
combine = require 'stream-combiner'

#p = require 'path'

# ==========================

distPath = './dist'

htmlminOptions =
  removeComments: true
  removeCommentsFromCDATA: true
  collapseWhitespace: true
  # conservativeCollapse: true # otherwise <i> & text squished
  collapseBooleanAttributes: true
  removeAttributeQuotes: true
  removeRedundantAttributes: true
  caseSensitive: true
  minifyJS: true
  minifyCSS: true

# ==========================

# dev & prod use
gulp.task 'css', ->
  gulp.src './src/css/b-app.less'
    # TODO: wait for minifyCss to support sourcemaps
#    .pipe gp.sourcemaps.init()
    # TODO: switch out font-awesome woff path w/ CDN path
    # .pipe replace "../bower_components/font-awesome/fonts", "//cdn.jsdelivr.net/fontawesome/4.1.0/fonts"
    .pipe gp.less paths: './src/b-*/b-*.less' # @import path
    .pipe gp.minifyCss cache: true, keepSpecialComments: 0 # remove all
#    .pipe gp.sourcemaps.write './'
    .pipe gulp.dest distPath

gulp.task 'html-prod', ->
  gulp.src ['./src/index.html']
#    .pipe gp.replace "ng-app", "ng-app ng-strict-di"
    .pipe gp.htmlReplace
      css: 'dist/b-app.css'
      js: 'dist/b-app.js'
    .pipe gp.replace '../dist/favicon.ico', 'dist/favicon.ico' # for b-map.coffee loading topojson
    .pipe gp.htmlmin htmlminOptions
    .pipe gulp.dest './' # to root for gh-pages use

gulp.task 'js-dev', ->
  gulp.src ['./src/b-*/b-*.coffee', './src/js**/b-*.coffee'] # js** glob to force output to same subdir
    .pipe gp.plumber()
    .pipe gp.sourcemaps.init()
    .pipe gp.coffee()
    .pipe gp.ngAnnotate() # ngmin doesn't annotate coffeescript wrapped code
    .pipe gp.sourcemaps.write('./')
    .pipe gulp.dest './src'

gulp.task 'js-prod', ->
  # inline templates
  ngTemplates = gulp.src './src/b-*/b-*.html'
    .pipe gp.htmlmin htmlminOptions
    .pipe gp.angularTemplatecache module: 'B.Templates', standalone: true # annotated already

  # compile cs & annotate for min
  ngModules = gulp.src ['./src/b-*/b-*.coffee', './src/js**/b-*.coffee']
    .pipe gp.plumber()
    .pipe gp.replace '../dist/', 'dist/' # for b-map.coffee loading topojson
    .pipe gp.replace "# 'B.Templates'", "'B.Templates'" # for b-app.coffee $templateCache
    .pipe gp.coffee()
    .pipe gp.ngAnnotate() # ngmin doesn't annotate coffeescript wrapped code

  # src that need min
  otherSrc = [
    './src/bower_components/topojson/topojson.js'
    './src/bower_components/plottable/plottable.js'
  ]
  other = gulp.src otherSrc

  # min above
  min = streamqueue(objectMode: true, ngTemplates, ngModules, other)
    .pipe gp.uglify()

  # src already min
  otherMinSrc = [
    './src/bower_components/angular/angular.min.js'
    './src/bower_components/angular-bootstrap/ui-bootstrap-tpls.min.js'
    './src/bower_components/d3/d3.min.js'
  ] # order is respected
  otherMin = gulp.src otherMinSrc

  # concat
  streamqueue objectMode: true, otherMin, min # otherMin 1st b/c has angular
    .pipe gp.concat 'b-app.js'
    .pipe gulp.dest distPath

gulp.task 'server', ->
  gulp.src('./').pipe gp.webserver(
    fallback: 'index.html' # for angular html5mode
    port: 3000
  )

# ==========================

gulp.task 'watch', ->
  gulp.src ['./src/b-*/b-*.less', './src/css/b-app.less']
    .pipe gp.watch {emit: 'one', name: 'css'}, ['css']

  jsSrc = [
    './src/b-*/b-*.coffee', './src/js**/b-*.coffee'
    './src/b-*/b-*.html'
    # './src/bower_components/**/*.js'
    # TODO: gulp watch can't see files added after bower install unless using glob option
  ]
  gulp.src(jsSrc).pipe gp.watch {emit: 'one', name: 'js'}, ['js-dev']

#  gulp.src ['./src/index.html']
#    .pipe gp.watch {emit: 'one', name: 'html'}, ['html-prod']

gulp.task 'dev', ['watch', 'server'], ->
  console.info "Please browse to http://localhost:3000/src"; return

gulp.task 'prod', ['css', 'js-prod', 'html-prod', 'server'], ->
  console.info "Please browse to http://localhost:3000"; return
