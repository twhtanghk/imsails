gulp = require 'gulp'
gutil = require 'gulp-util'
bower = require 'bower'
concat = require 'gulp-concat'
sass = require 'gulp-sass'
minifyCss = require 'gulp-minify-css'
rename = require 'gulp-rename'
sh = require 'shelljs'
browserify = require 'browserify'
bower = require 'gulp-bower'
source = require 'vinyl-source-stream'

paths = sass: ['./scss/**/*.scss']

gulp.task 'default', ['plugin', 'sass', 'coffee']

gulp.task 'sass', (done) ->
  gulp.src('./scss/ionic.app.scss')
    .pipe(sass())
    .pipe(gulp.dest('./www/css/'))
    .pipe(minifyCss({
      keepSpecialComments: 0
    }))
    .pipe(rename({ extname: '.min.css' }))
    .pipe(gulp.dest('./www/css/'))
    
gulp.task 'coffee', ->
  browserify(entries: ['./www/js/index.coffee'])
    .transform('coffeeify')
    .transform('debowerify')
    .bundle()
    .pipe(source('index.js'))
    .pipe(gulp.dest('./www/js/'))

gulp.task 'plugin', ->
  for plugin in require('./package.json').cordovaPlugins
  	sh.exec "cordova plugin add #{plugin}"
  
gulp.task 'watch', ->
  gulp.watch(paths.sass, ['sass'])

gulp.task 'install', ['git-check'], ->
  bower.commands.install().on 'log', (data) ->
    gutil.log('bower', gutil.colors.cyan(data.id), data.message)
    
gulp.task 'git-check', (done) ->
  if (!sh.which('git'))
    console.log(
      '  ' + gutil.colors.red('Git is not installed.'),
      '\n  Git, the version control system, is required to download Ionic.',
      '\n  Download git here:', gutil.colors.cyan('http://git-scm.com/downloads') + '.',
      '\n  Once git is installed, run \'' + gutil.colors.cyan('gulp install') + '\' again.'
    )
    process.exit(1)
  done()