'use strict';

var gulp = require('gulp');
var coffee = require('gulp-coffee');
var browserify = require('browserify');
var uglify = require('gulp-uglify');
var gutil = require('gulp-util');
var mocha = require('gulp-mocha');
var rename = require('gulp-rename');
var docco = require('gulp-docco');
var register = require('coffee-script/register');
var del = require('del');
var sourcemaps = require('gulp-sourcemaps');
var budo = require('budo')

//var transform = require('vinyl-transform'); - previously used but doesnt work :S
//var watchify = require('watchify'); // TODO - Eventually use watchify

// Build the docs with docco
gulp.task('docs', function(){
  gulp.src("./src/**/*.coffee")
  .pipe(docco())
  .pipe(gulp.dest('./docs'))
});


// Build the website from the markdown guides and place in the HTML page
gulp.task('guide', function(){
  
});

// Make ready for the web
// TODO - Turn on or off DEBUG gulp builds

gulp.task('web', ['build'], function(){

  // As far as I can tell, vinyl-transform is fucking retarded
  // and doesnt work properly so I've implemented what should
  // work here instead. This vinylizeBrowserify is basically
  // vinyl transform but with a few silly breaking lines removed
  // This could be all to do with browserify but honestly, the
  // line in vinyl-transform is redundant:
  // lines 25,26:
  //  from([contents])
  //    .pipe(output)

  var through2 = require('through2')
  var bl = require('bl')


  function vinylizeBrowserify(transform) {
    return through2.obj(write, flush)

    function write(file, _, next) {

      if (file.isNull()) return this.push(file), next()

      // Actually perform browserify here
      var output = transform(file.path)
      var contents = file.contents
      var stream = this

      if (file.isStream()) {
        file.contents.pipe(output)
        file.contents.on('error', stream.emit.bind(stream, 'error'))
        file.contents = output
        this.push(file)
        return next()
      }

      // Remove the initial line that was screwing everything up
      output
        .pipe(bl(function(err, buffer) {
          if (err) return stream.emit('error', err)
          file.contents = buffer
          stream.push(file)
          next()
        }))
    }

    function flush() {
      this.push(null)
      this.emit('end')
    }
  }

  var browserified = vinylizeBrowserify ( function(filename) {
    return browserify({ debug: true })
      .require(require.resolve(filename), { entry: true })
      .bundle()
      .on('error', function (err) { console.error(err); })
  });

  return gulp.src('./build/src/pxl.js')
    .pipe(browserified)
    .pipe(gulp.dest('./build/lib'))
    .pipe(gulp.dest('./html/js'))
    .pipe(uglify())
    .pipe(rename('pxl.min.js'))
    .pipe(gulp.dest('./build/lib'))
    .pipe(gulp.dest('./html/js'));
   
});

// Clean by removing the build directories
gulp.task('clean', function(cb) {
  return del(['build'], cb);
});


// Build and run basic tests
gulp.task('test', function(cb) {
  gulp.src( ["./test/*.coffee"], {base: ".", read: false})
  .pipe(mocha())
});



// Basic build - run through coffee and sourcemaps
// Latest coffeescript can generate its out sourcemaps but for now Im using gulps
// Source maps are built inline for now
// TODO - Turn this off for release build

gulp.task('build', ['clean'], function(){
  return gulp.src(["./src/**/*.coffee"],{base: "."})
    .pipe(sourcemaps.init())
    .pipe(coffee({bare: true, map: true}).on('error',gutil.log))
    .pipe(sourcemaps.write())
    .pipe(gulp.dest('./build'));
});


gulp.task('examples', function() {
  return gulp.src(["./examples/*.coffee"])
    .pipe(coffee({bare: true}).on('error',gutil.log))
    .pipe(gulp.dest('./html/js/examples'));
});


// Dev environment setup
// TODO - Pass the debug parameter
// TODO - the order seems to be screwed up a bit :S
gulp.task('dev', ['web','examples'], function(cb) {

  var watch_src = gulp.watch('src/**/*.coffee', ['web']);
  var watch_examples = gulp.watch('examples/*.coffee', ['examples']);

  //dev server
  budo("./html/index.html", {
    stream: process.stdout, // pretty-print requests
    live: true,             // live reload & CSS injection
    dir: 'html',             // directory to serve
  }).on('exit', cb)

  watch_src.on('change', function(event) {
    console.log('File ' + event.path + ' was ' + event.type + ', running tasks...');
  });

  watch_examples.on('change', function(event) {
   console.log('File ' + event.path + ' was ' + event.type + ', running tasks...');
  });

  

});



// Default - build and test all the things then quit
gulp.task('default', ['web','examples','docs','test'], function() {

});
