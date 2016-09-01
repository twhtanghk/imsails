argv = require('yargs').argv
gulp = require 'gulp'
bower = require 'bower'
sass = require 'gulp-sass'
less = require 'gulp-less'
concat = require 'gulp-concat'
merge = require 'streamqueue'
minifyCss = require 'gulp-minify-css'
rename = require 'gulp-rename'
sh = require 'shelljs'
browserify = require 'browserify'
bower = require 'gulp-bower'
source = require 'vinyl-source-stream'
rework = require 'gulp-rework'
reworkNPM = require 'rework-npm'
cleanCSS = require 'gulp-clean-css'
uglify = require 'gulp-uglify'
templateCache = require 'gulp-angular-templatecache'
whitespace = require 'gulp-css-whitespace'
del = require 'del'

gulp.task 'default', ['browser']

gulp.task 'css', (done) ->
  [lessAll, scssAll, cssAll] = [
    gulp.src ['./scss/bootstrap.less']
      .pipe less()
      .pipe concat 'less-files.less'
    gulp.src ['./scss/ionic.app.scss']
      .pipe sass()
      .pipe concat 'scss-files.scss'
    gulp.src 'www/css/index.css'
      .pipe whitespace()
      .pipe rework reworkNPM shim: 'angular-toastr': 'dist/angular-toastr.css'
      .pipe concat 'css-files.css'
  ]
  merge objectMode: true, lessAll, cssAll, scssAll
    .pipe concat 'ionic.app.css'
    .pipe gulp.dest 'www/css/'
    .pipe cleanCSS()
    .pipe rename extname: '.min.css'
    .pipe gulp.dest 'www/css/'

gulp.task 'copy', ->
  gulp.src(if argv.prod then './www/js/config/production.coffee' else './www/js/config/development.coffee')
    .pipe(rename('env.coffee'))
    .pipe(gulp.dest('./www/js/'))

gulp.task 'coffee', ['copy', 'template'],  ->
  browserify(entries: ['./www/js/index.coffee'])
    .transform('coffeeify')
    .transform('debowerify')
    .bundle()
    .pipe(source('index.js'))
    .pipe(gulp.dest('./www/js/'))

gulp.task 'template', ->
  gulp.src('./www/templates/**/*.html')
    .pipe(templateCache(root: 'templates', standalone: true))
    .pipe(gulp.dest('./www/js/'))

gulp.task 'pre-android', ->
  argv.prod = true
  sh.exec "cordova platform rm android"
  sh.exec "cordova platform add android"
  sh.exec "ionic resources android"

gulp.task 'android', ['pre-android', 'plugin', 'css', 'coffee'], ->
  sh.exec "cordova build android"

gulp.task 'pre-browser', ->
  sh.exec "cordova platform rm browser"
  sh.exec "cordova platform add browser"
  sh.exec "ionic resources browser"

gulp.task 'browser', ['pre-browser', 'plugin', 'css', 'coffee'], ->
  sh.exec "cordova build browser"

gulp.task 'plugin', ->
  for plugin in require('./package.json').cordovaPlugins
    sh.exec "cordova plugin add #{plugin}"

gulp.task 'clean', ->
  sh.exec "cordova platform rm browser"
  sh.exec "cordova platform rm android"
  del [
    'node_modules'
    'www/lib'
    'resources/browser'
    'resources/android'
    'plugins'
  ]
