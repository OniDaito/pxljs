# PXLjs

## Introduction

PXLjs is designed to make WebGL quick and easy to use for these who want results quick, but also flexible enough for more advanced coding. It takes the form of a large scene-graph plus ubershader, with all of the functionality exposed for adapting and extending.

PXLjs is written in CoffeeScript but can just as easily be used with Plain Old Javascript if you so wish. Whilst the API calls and documentation use CoffeeScript in the main, the commands are roughly the same in Javascript.

## Downloading and Building

You can download the source from here on github. Simply checkout the project and run the following command...

    npm install

This should pull down the development pre-requisites, build the library and run the tests.  

To run the development build, type the following command inside the base directory...

    gulp dev

The *dev* command builds the library but also runs a webserver on port **9966** on localhost, so you can view the built examples in your browser.

I used [gulp](http://gulpjs.com/) to manage the build system. Previously I had a makefile which I might re-instate in the future.

## Basic Use

PXLjs is a single, minified Javascript source, with associated json and image files for the various textures and models you may wish to load. 

If you wish to develop PXLjs and modify it whilst you are writing your program, you might prefer to use the Javascript builds or the raw coffeescript source. The former can be found in the **build** directory once you've built the source.

### Simple example in Coffeescript
<pre>

init = () ->
  v0 = new PXLjs.Vertex(new PXLjs.Vec3(-1,-1,0), new PXLjs.Colour.RGBA.WHITE())
  v1 = new PXLjs.Vertex(new PXLjs.Vec3(0,1,0), new PXLjs.Colour.RGBA.WHITE())
  v2 = new PXLjs.Vertex(new PXLjs.Vec3(1,-1,0), new PXLjs.Colour.RGBA.WHITE())

  t = new PXLjs.Geometry.Triangle(v0,v1,v2)

  @node = new PXLjs.Node t 
  @camera = new PXLjs.Camera.PerspCamera()
  @node.add @camera

  uber = new PXL.GL.UberShader @node
  @node.add uber


draw = () ->
  GL.clearColor(0.15, 0.15, 0.15, 1.0)
  GL.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT)
  @node.draw()

params = 
  canvas : 'webgl-canvas'
  context : @
  init : init
  draw : draw

cgl = new PXL.App params

</pre>


### Simple usecase in Javascript


<pre>
var cgl, draw, init, params;

init = function() {
  var t, v0, v1, v2, uber;
  v0 = new PXLjs.Vertex(new PXLjs.Vec3(-1, -1, 0), new PXLjs.Colour.RGBA.WHITE());
  v1 = new PXLjs.Vertex(new PXLjs.Vec3(0, 1, 0), new PXLjs.Colour.RGBA.WHITE());
  v2 = new PXLjs.Vertex(new PXLjs.Vec3(1, -1, 0), new PXLjs.Colour.RGBA.WHITE());
  t = new PXLjs.Geometry.Triangle(v0, v1, v2);
  this.node = new PXLjs.Node(t);
  this.camera = new PXLjs.Camera.PerspCamera();
  this.node.add(this.camera);
  uber = new PXL.GL.UberShader(this.node); 
};

draw = function() {
  GL.clearColor(0.15, 0.15, 0.15, 1.0);
  GL.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT);
  this.node.draw();
};

params = {
  canvas: 'webgl-canvas',
  context: this,
  init: init,
  draw: draw
};

cgl = new PXL.App(params);
</pre>
