"use strict"

gulp = require "gulp"
concat = require "gulp-concat"
plumber = require "gulp-plumber"
coffee = require "gulp-coffee"

gulp.task "coffee", ->

  gulp.src("./src/**/*.coffee")
  .pipe(plumber())
  .pipe(coffee(bare : true))
  .pipe(concat("baio-angular-d3.js"))
  .pipe(gulp.dest('./distr'))

  gulp.src("./example/app.coffee")
  .pipe(plumber())
  .pipe(coffee())
  .pipe(concat("app.js"))
  .pipe(gulp.dest('./example'))


gulp.task "watch", ->
  gulp.watch ["./example/app.coffee", "./src/**/*.coffee"], ["coffee"]

gulp.task "default", ["coffee"]


