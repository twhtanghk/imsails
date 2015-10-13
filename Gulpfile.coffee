argv = require('yargs').argv
gulp = require 'gulp'
bower = require 'bower'
sass = require 'gulp-sass'
minifyCss = require 'gulp-minify-css'
rename = require 'gulp-rename'
sh = require 'shelljs'
browserify = require 'browserify'
bower = require 'gulp-bower'
source = require 'vinyl-source-stream'
uglify = require 'gulp-uglify'
gulpif = require 'gulp-if'
templateCache = require 'gulp-angular-templatecache'

paths = sass: ['./scss/**/*.scss']

gulp.task 'default', ['browser']

gulp.task 'sass', (done) ->
  gulp.src('./scss/ionic.app.scss')
    .pipe(sass())
    .pipe(gulp.dest('./www/css/'))
    .pipe(minifyCss({
      keepSpecialComments: 0
    }))
    .pipe(rename({ extname: '.min.css' }))
    .pipe(gulp.dest('./www/css/'))
    
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
  sh.exec "ionic resources"
  
gulp.task 'android', ['pre-android', 'plugin', 'sass', 'coffee'], ->
  sh.exec "cordova build android"

gulp.task 'pre-browser', ->
  sh.exec "cordova platform rm browser"
  sh.exec "cordova platform add browser"
  sh.exec "ionic resources"
  
gulp.task 'browser', ['plugin', 'sass', 'coffee'], ->
  sh.exec "cordova build browser"

gulp.task 'plugin', ->
  for plugin in require('./package.json').cordovaPlugins
  	sh.exec "cordova plugin add #{plugin}"
  sh.exec "rm platforms/android/libs/android-support-v4.jar"