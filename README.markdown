
# PXLjs 

### v0.1.0

![Build Status Images](https://travis-ci.org/OniDaito/PXLjs.svg)

## A WebGL Library for CoffeeScript and Vanilla Javascript.


PXLjs is a WebGL Library designed to help programmers create 3D programs for the World-Wide-Web using [CoffeeScript](http://coffeescript.org) or normal Javscript. This project is open-source and designed to provide useful functions for beginners without restricting the option to program in raw WebGL.


## Download and Installation

You can get PXLjs in a variety of ways: 

* As a [zip direct download](http://www.pxljs.com/pxljs.zip) of the minified and standard library from [pxljs.com](http://pxljs.com).
* The latest [zip from github](https://github.com/OniDaito/pxljs/archive/master.zip).
* Visit the [Github page](https://www.github.com/OniDaito/PXLjs) and clone the respository.
* Directly through npm using the command below.

    npm install pxljs

## Requirements

To use PXLjs you just need a good text editor and a recent web-browser. You can use PXLjs either with normal Javascript or CoffeeScript; it is provided ready compiled. However, if you are working on a more complicated project, its useful to work with the non-compiled, coffeescript version using node.

## Building

PXLjs uses [gulp]() as it's build engine. The following command will setup a dev environment for you to play with, including a webserver for testing

    gulp dev

Browse to ...
     http://localhost:9966/examples/helloworld.html
... to get started

The [building and developing PXLjs page](https://github.com/OniDaito/pxljs/blob/master/docs/index.markdown#downloading-and-building) has more.

## Getting Started

### Starting a new project.

First, create a new folder for your project. Into this we will place our **index.html** and the pxljs library file, **pxljs.min.js** which you can find in the lib directory.

Your HTML page should look something like this:

<pre>
&lt;!doctype html&gt;
&lt;head&gt;

&lt;title&gt;My First PXLjs Page&lt;/title&gt;
&lt;/head&gt;
&lt;body&gt;
&lt;/body&gt;
&lt;/html&gt;
</pre>

Inside your html page insert the following lines...

<pre>
&lt;canvas id="webgl-canvas" style="border: none;" width="580" height="580"&gt;&lt;/canvas&gt;
&lt;script type="text/javascript" src="pxljs.min.js"&gt;&lt;/script&gt;
</pre>

...inside the body section.

### Using CoffeeScript to compile your code.

My preference is to use coffeescript to write my code. If you are not familar with coffeescript or prefer to use javascript, you can! Just skip to the next section.

Lets start by writing two basic functions, our init and draw functions. Create a new file called **helloworld.coffee.**

<pre>

init = () ->
  white = new PXL.Colour.RGBA.WHITE() 
  
  v0 = new PXL.Geometry.Vertex 
    p : new PXL.Math.Vec3(-1,-1,0) 
    c : white 

  v1 = new PXL.Geometry.Vertex
    p : new PXL.Math.Vec3(0,1,0)
    c : white

  v2 = new PXL.Geometry.Vertex
    p : new PXL.Math.Vec3(1,-1,0)
    c : white


  t = new PXL.Geometry.Triangle(v0,v1,v2)

  vertexMaterial = new PXL.Material.VertexColourMaterial()
  
  @node = new PXL.Node t 
  camera = new PXL.Camera.PerspCamera()
  
  @node.add camera
  @node.add vertexMaterial
  @node.add new PXL.GL.UberShader(@node)

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

Lets take a closer look at these functions and the lines inside...

<pre>
  v0 = new PXL.Geometry.Vertex 
    p : new PXL.Math.Vec3(-1,-1,0) 
    c : white 
</pre>

This line creates a new Vertex consisting of a Vec3 and an RGBA Colour. A Vertex is the smallest unit of geometry possible and can contain things like a normal, a tangent, a colour, etc.

PXLjs has built-in special names for vertex information. For example **c** refers to the colour attached to this vertext, whereas **p** refers to the position. Others can be found in the [API Docs for Vertex](http://docs.pxljs.com/geometry/primitive.html).

The Vec3 represents a position in space and is part of the [PXLjs Maths Library](http://docs.pxljs.com/math/math.html) which has many primitives for you to play with. The Colour.RGBA.WHITE() is a 4 component colour, in this case white, that is passed along with the position when creating the vertex.

<pre>
    t = new PXLjs.Geometry.Triangle(v0,v1,v2)
</pre>

As you may have guessed, a Triangle contains 3 vertices and is a simple collection of vertices. It is a face and therefore can have face normals and such.

<pre>
  @node = new PXLjs.Node t 
  @camera = new PXLjs.Camera.PerspCamera()
  @node.add @camera
</pre>

The first line creates a [Node object](https://github.com/OniDaito/pxljs/blob/master/docs/node.markdown). These are quite useful in PXLjs. They combine geometry with a matrix, shaders, cameras and even other nodes, in order to create a partial scene graph. The node system is fairly flexible and takes care of creating buffers, bind calls and shader uniform calls for you.

The second line creates a perspective camera with the default settings. This should allow us to see our first triangle. We attach it to the node in the last line.

<pre>
  vertexMaterial = new PXL.Material.VertexColourMaterial()
</pre>

PXLjs uses the concept of materials. This is fairly common amongst most 3D programs and possibly familiar to many. In this case, we are using a basic material that reads flat colours from the vertices themselves.

<pre>
  uber = PXL.GL.UberShader @node
</pre>

PXLjs uses an [ubershader](http://stackoverflow.com/questions/23726421/how-should-i-organize-shader-system-with-opengl) to perform most of it's effects. When you just want things to work as advertised, with lights, shadows and materials and you don't want to have to mess with any shaders, use the built-in ubershade simply by passing in the node you want to shade.

The ubershader is called last. This is important as it scans the nodes you pass to it, in order to detect what shader chunks it needs to include.

You can [create your own shaders](https://github.com/OniDaito/pxljs/blob/master/docs/shaders.markdown) and add these to the node you want to draw. PXLjs creates buffers for you automagically and presents these to the shaders using a [contract](http://docs.pxljs.com/gl/contract.html); a mapping between CPU variables and JS variables. 

<pre>
  draw = () ->
    GL.clearColor(0.15, 0.15, 0.15, 1.0)
    GL.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT)
    @node.draw()
</pre>

The draw function is quite straight forward. PXLjs creates a GL object that allows you to execute normal WebGL commands for the current context, like clearing the screen, setting depth buffers or any of the normal WebGL functions. The context is automatically set for you, and the draw function is called 60 times a second.

The final line calls the draw function on our node, actually drawing to the screen.

<pre>
  cgl = new PXLjs.App('webgl-canvas', this, init, draw)
</pre>

This last line is the final piece of the puzzle. We create an App that takes a number of parameters...

* The 'webgl-canvas' refers to which canvas object on the page we want to use (by id)
* context refers to the object to be wrapped by PXLjs (in this case, the global context)
* init refers to the init method we just defined above.
* draw refers to which function will be used by PXLjs to draw to the screen.

And that is it. Compile this with CoffeeScript using the following command inside your new directory...

<pre>
  coffee -o . helloworld.coffee
</pre>

...and you should see a file called **helloworld.js** appear in your new folder. Lets go back to your index.html page and add the following line:

<pre>
  &lt;script type="text/javascript" src="helloworld.js"&gt;&lt;/script&gt;
</pre>

As we are performing requests to grab our shader, we should run a small websever to test our page. If you are on OSX or Linux you should have access to python. Open up a terminal, navigate to your directory and type...

<pre>
  python -m SimpleHTTPServer
</pre>

Now browse to **http://localhost:8000** page in your favorite web-browser and voila! You should see your first triangle!
Now take a look at the examples to see how you can make wonderful, hardware accelerated graphics on the web.

### Going with vanilla Javascript.
If you are a purist and prefer to use Javascript you can! The objects PXLjs and GL are exported to the global namespace so you can use them as normal javscript objects.

You may also have noticed that the **lib** directory contains a sub-directory called **pxljs**. Inside here, you will find all the compiled modules if you prefer to use node.js and include / require just the files you need.

PXLjs uses [uglify](https://github.com/mishoo/UglifyJS) and [browserify](http://browserify.org/) to create its final pxljs.min.js file, so if you follow the conventions laid down by these libraries, you should have no trouble.

#### Same program as above but in Javascript

<pre>

var cgl, draw, init, params;

init = function() {
  var t, v0, v1, v2;
  v0 = new PXLjs.Vertex(new PXLjs.Vec3(-1, -1, 0), new PXLjs.Colour.RGBA.WHITE());
  v1 = new PXLjs.Vertex(new PXLjs.Vec3(0, 1, 0), new PXLjs.Colour.RGBA.WHITE());
  v2 = new PXLjs.Vertex(new PXLjs.Vec3(1, -1, 0), new PXLjs.Colour.RGBA.WHITE());
  t = new PXLjs.Geometry.Triangle(v0, v1, v2);
  this.node = new PXLjs.Node(t);
  this.camera = new PXLjs.Camera.PerspCamera();
  this.node.add(this.camera);
  PXL.GL.UberShader(this.node);
};

draw = function() {
  GL.clearColor(0.15, 0.15, 0.15, 1.0);
  GL.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT);
  return this.node.draw();
};

params = {
  canvas: 'webgl-canvas',
  context: this,
  init: init,
  draw: draw
};

cgl = new PXL.App(params);

</pre>

The Javascript version is very similar and if that's your bag, definitely go with that.

## API Documentation

Full API documentation can be found in the docs directory or online at [http://docs.pxljs.com](http://docs.pxljs.com).

## Further Reading here on GitHub

* [Introduction](https://github.com/OniDaito/pxljs/blob/master/docs/index.markdown) 


## Things still to do...

* SIMD Extensions in the math library
* BSP / Quad Tree structures for gaming
* Physically Based Rendering (PBR)
* Optimisations for more speed
* Better Debug settings
* WebGL2 support in the build
* and more! Please submit issues here on the github page

## Thanks to...

* Katie Eagleton.
* Seb Falk.
* Raymond Hill.
