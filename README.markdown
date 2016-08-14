
# PXLjs 

### v0.0.0

![Build Status Images](https://travis-ci.org/OniDaito/PXLjs.svg)

## A WebGL Library for CoffeeScript and Vanilla Javascript.


PXLjs is a WebGL Library designed to help programmers create 3D programs for the World-Wide-Web using [CoffeeScript](http://coffeescript.org) or normal Javscript. This project is open-source and designed to provide useful functions for beginners without restricting the option to program in raw WebGL.


## Download and Installation

You can get PXLjs in a variety of ways: 

* As a [zip direct download](http://www.pxljs.com/pxljs.zip).
* Visit the [Github page](https://www.github.com/OniDaito/PXLjs) and clone the respository.
* Directly through npm using the command below.

## Requirements


To use PXLjs you just need a good text editor and a recent web-browser. You can use PXLjs either with normal Javascript or CoffeeScript; it is provided ready compiled. However, if you are working on a more complicated project, its useful to work with the non-compiled, coffeescript version using node. In which case you will need:


* Node.js version 0.8.0 or above
* browserify version 2.7.1 or above
* uglify-js version 2.2 or above
* coffeescript 1.6.2 or above
* mocha 1.8.2 or above
* chai 1.5.0 or above
* Docco

mocha and chai are only needed to run the tests (which is a good idea if you are playing with the maths library). Docco is required to build the documentation. NPM will install all of these for you.

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
&lt;script type="text/javascript" src="coffeegl.min.js"&gt;&lt;/script&gt;
</pre>

...inside the body section.
Next, we will need a basic shader for our first example. You can write your own as either a file or a string, using components from PXLjs. Lets copy our most basic shader, **basic_vertex_colour.glsl** from the shaders directory.

We have everything we need in place now, so lets start work on our first ever triangle!

### Using CoffeeScript to compile your code.

My preference is to use coffeescript to write my code. If you are not familar with coffeescript or prefer to use javascript, you can! Just skip to the next section.

Lets start by writing two basic functions, our init and draw functions. Create a new file called **helloworld.coffee.**

<pre>
  init = () ->
    v0 = new PXLjs.Vertex(new PXLjs.Vec3(-1,-1,0), new PXLjs.Colour.RGBA.WHITE())
    v1 = new PXLjs.Vertex(new PXLjs.Vec3(0,1,0), new PXLjs.Colour.RGBA.WHITE())
    v2 = new PXLjs.Vertex(new PXLjs.Vec3(1,-1,0), new PXLjs.Colour.RGBA.WHITE())

    t = new PXLjs.Geometry.Triangle(v0,v1,v2)

    r = new PXLjs.Request('basic_vertex_colour.glsl')
    r.get (data) =>
      shader = new PXLjs.Shader(data)
      shader.bind()

    @node = new PXLjs.Node t 

    @camera = new PXLjs.Camera.PerspCamera()

    @node.add @camera

  draw = () ->
  
    GL.clearColor(0.15, 0.15, 0.15, 1.0)
    GL.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT)
    @node.draw()

  params = 
    canvas : 'webgl-canvas'
    context : @
    init : init
    debug : true
    draw : draw

  cgl = new PXL.App params

</pre>

Lets take a closer look at these functions and the lines inside...

<pre>
  v0 = new PXLjs.Vertex(new PXLjs.Vec3(-1,-1,0), new PXLjs.Colour.RGBA.WHITE())
</pre>

This line creates a new Vertex consisting of a Vec3 and an RGBA Colour. A Vertex is the smallest unit of geometry possible and can contain things like a normal, a tangent, a colour, etc.
The Vec3 represents a position in space and is part of the PXLjs Maths Library which has many primitives for you to play with. The Colour.RGBA.WHITE() is a 4 component colour, in this case white, that is passed along with the position when creating the vertex.

<pre>
    t = new PXLjs.Triangle(v0,v1,v2)
</pre>

As you may have guessed, a Triangle contains 3 vertices and is a simple collection of vertices. It is a face and therefore can have face normals and such.

<pre>
    r = new PXLjs.Request('basic_vertex_colour.glsl')
    r.get (data) =>
      shader = new PXLjs.Shader(data)
      shader.bind()
</pre>

PXLjs has a loading mechanism where a request can be sent for an external file. In this case, we are asking for a glsl file that represents our shader. We call the get method, passing it a function that is called when the file is loaded. The data will be text that pass to our new PXLjs.Shader. We then bind this shader, thus loading it onto our graphics card.

<pre>
  @node = new PXLjs.Node t 
  @camera = new PXLjs.Camera.PerspCamera()
  @node.add @camera
</pre>

The first line creates a Node object. These are quite useful in PXLjs. They combine geometry with a matrix, shaders, cameras and even other nodes, in order to create a partial scene graph. The node system is fairly flexible and takes care of creating buffers, bind calls and shader uniform calls for you.

The second line creates a perspective camera with the default settings. This should allow us to see our first triangle. We attach it to the node in the last line.

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
* this refers to the object to be wrapped by PXLjs (in this case, the global context)
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

Now browse to **http://localhost:8000** page in your favorite web-browser (so long as it isn't Windows Internet Explorer) and voila! You should see your first triangle!
Now take a look at the examples to see how you can make wonderful, hardware accelerated graphics on the web.

### Going with vanilla Javascript.
If you are a purist and prefer to use Javascript you can! The objects PXLjs and GL are exported to the global namespace so you can use them as normal javscript objects.

You may also have noticed that the **lib** directory contains a sub-directory called **coffeegl**. Inside here, you will find all the compiled modules if you prefer to use node.js and include / require just the files you need.

PXLjs uses uglify and browserify to create its final coffeegl.min.js file, so if you follow the conventions laid down by these libraries, you should have no trouble.

## API Documentation
Full API documentation can be found in the docs directory or online at [http://docs.coffeegl.com](http://docs.coffeegl.com).

## About

CoffeGL is designed to make the repetitive and common tasks in WebGL development easy and straight-forward. I decided to go down the route of using a node-based system, similar to a scene graph but one that could be ignored if a developer so chooses. The idea is that one can create something quickly to see how it looks, then optimise and adapt the code easily and quickly.

I decided to write this in CoffeeScript as oppose to native Javascript, largely because Javascript has some idiosyncracies that I'm not very fond of. To put it bluntly, we all know that javscript mostly sucks, and there are various ways to get around that. Dart is one I'd consider, along with CoffeeScript and in the future, I may move to Dart if the situation arises. For now though, CoffeeScript, along with Node.js, provides a useful abstraction, allowing me to get work done.

All the code is open-source and is available on my GitHub Page. Please add comments, pull requests and similar there, and do feel free to send me any comments at oni@section9.co.uk. Let me know if you use PXLjs, have comments or queries or suggestions on how we can improve.

## Things still to do
* SIMD Extensions in the math library
* BSP / Quad Tree structures for gaming
* Add lighting to the shader library functions
* Remove _DIM tests for compatibility with Canon.js
* ....loads more! Please check the github page for issues.

## Further Information

## Credits

* Katie Eagleton.
* Seb Falk.
* Raymond Hill for the Voroni implementation.
* @schteppe of Canon.js fame.
* NASA for the Earth Images