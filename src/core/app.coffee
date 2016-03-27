### ABOUT
             .__   
_________  __|  |  
\____ \  \/  /  |  
|  |_> >    <|  |__
|   __/__/\_ \____/
|__|        \/     js

                    PXL.js
                    Benjamin Blundell - ben@pxljs.com
                    http://pxljs.com

This software is released under the MIT Licence. See LICENCE.txt for details

- Resources

* http://www.yuiblog.com/blog/2007/06/12/module-pattern/
* http://www.plexical.com/blog/2012/01/25/writing-coffeescript-for-browser-and-nod/
* https://github.com/field/FieldKit.js

- TODO 

* Not sure we want to make this a listener for events. I suspect we need a keyboard eventor
  style class and touch eventor class that takes a DOM?

###


{Vec2,Vec3, Vec4, Matrix4} = require "../math/math" # Makes this Matrix4 global for this file/closure only
{Shader} = require "../gl/shader" 
{PerspCamera, OrthoCamera} = require "../camera/camera" 
{makeMouseEmitter, removeMouseEmitter } = require "../interact/mouse"
{makeTouchEmitter,removeTouchEmitter} = require "../interact/touch"
{makeKeyEmitter, removeKeyEmitter} = require "../interact/key"
{Colour} = require "../colour/colour"
{PXLError, PXLWarning, PXLLog} = require "../util/log"
{makeDebugContext} = require "../util/debug"


# OnEachFrame function
# Taken from http://nokarma.org/2011/02/02/javascript-game-development-the-game-loop/index.html

### App ###

# The master class in effect. This class takes functions from your application and calls them
# as and when needed
# TODO - is Context a better name? I think so. We should change it

class App

  # constructor - Takes an object with the following parameters
  # 
  # canvas: canvas element, 
  # context: the glcontext
  # init: an init function, called once,
  # draw:  a draw function (called 60 times a second)
  # update : update function (called as fast as possible), 
  # error: an error function and an optional switch for debug mode
  # delay_start : true/false - dont start automatically
  # destroy : a funtion that is called when the context is destroyed / shutdown
  # debug : true / false - set a global debug mode for this context

  constructor: (params) ->
    
    # Parse the basic parameters
    if not params.canvas?
      PXLError "No WebGL Canvas Provided"
      return

    @debug = if not params.debug? then false else params.debug
    @app_context = params.context
    @update = params.update
    @draw = params.draw
    @init = params.init
    @user_shutdown = params.shutdown

    @canvas = document.getElementById params.canvas
    if not @canvas
      PXLError "Trying to create an app on canvas that does not exist"
   
    @_pause = if not params.pause? then false else params.pause
    @height = @canvas.height
    @width = @canvas.width
    
    @_context()

    @

  _context : () ->

    # Deal with Context loss
    # TODO - Needs testing! :O
    cl = (event) =>
      event.preventDefault()

      # Remove the context from the applications list
      idx = 0
      for idx in PXL.Applications.length
        if PXL.Applications[i][0] = @
          break

      PXL.Applications.splice idx, 1

      @_context()

    @canvas.addEventListener "webglcontextlost", cl, false

    @_initContext() if not @gl?
  
    # Do we want such emitters by default? Generally we do right?
    makeMouseEmitter @
    makeTouchEmitter @
    makeKeyEmitter @

    @resizeCanvas(@canvas.width, @canvas.height)
    
    if @init?
      @init.call @app_context

    # Context time is the time im seconds that this context has run
    # TODO - Do we still use this really?
    @contextTime = 0

    window.onEachFrame @,@run if window?


  # Create the Actual webGL Context. This is called at startup and if the context is lost
  _initContext : () ->

    names = ["experimental-webgl", "webgl", "moz-webgl", "webkit-3d"]
    for name in names
      @gl = @canvas.getContext name
      if @gl?
        @_profile()
        @_framescounter = 0

        # TODO - Actually make a proper debug context :P
        if @debug
          PXLLog "creating OpenGL debug context"
          
          #makeDebugContext @gl

        return

    if not @gl
      @onError() if @onError?
      # TODO - Add a signal here perhaps? Event?
      PXLError "WebGL Not supported or context not found", "App" 
    
    @

    
  # TODO - Move profiling into some context that never changes?
  #  http://www.quirksmode.org/js/detect.html
  if navigator? 
    `var BrowserDetect = {
      init: function () {
        this.browser = this.searchString(this.dataBrowser) || "An unknown browser";
        this.version = this.searchVersion(navigator.userAgent)
          || this.searchVersion(navigator.appVersion)
          || "an unknown version";
        this.OS = this.searchString(this.dataOS) || "an unknown OS";
      },
      searchString: function (data) {
        for (var i=0;i<data.length;i++) {
          var dataString = data[i].string;
          var dataProp = data[i].prop;
          this.versionSearchString = data[i].versionSearch || data[i].identity;
          if (dataString) {
            if (dataString.indexOf(data[i].subString) != -1)
              return data[i].identity;
          }
          else if (dataProp)
            return data[i].identity;
        }
      },
      searchVersion: function (dataString) {
        var index = dataString.indexOf(this.versionSearchString);
        if (index == -1) return;
        return parseFloat(dataString.substring(index+this.versionSearchString.length+1));
      },
      dataBrowser: [
        {
          string: navigator.userAgent,
          subString: "Chrome",
          identity: "Chrome"
        },
        {   string: navigator.userAgent,
          subString: "OmniWeb",
          versionSearch: "OmniWeb/",
          identity: "OmniWeb"
        },
        {
          string: navigator.vendor,
          subString: "Apple",
          identity: "Safari",
          versionSearch: "Version"
        },
        {
          prop: window.opera,
          identity: "Opera",
          versionSearch: "Version"
        },
        {
          string: navigator.vendor,
          subString: "iCab",
          identity: "iCab"
        },
        {
          string: navigator.vendor,
          subString: "KDE",
          identity: "Konqueror"
        },
        {
          string: navigator.userAgent,
          subString: "Firefox",
          identity: "Firefox"
        },
        {
          string: navigator.vendor,
          subString: "Camino",
          identity: "Camino"
        },
        {   // for newer Netscapes (6+)
          string: navigator.userAgent,
          subString: "Netscape",
          identity: "Netscape"
        },
        {
          string: navigator.userAgent,
          subString: "MSIE",
          identity: "Explorer",
          versionSearch: "MSIE"
        },
        {
          string: navigator.userAgent,
          subString: "Gecko",
          identity: "Mozilla",
          versionSearch: "rv"
        },
        {     // for older Netscapes (4-)
          string: navigator.userAgent,
          subString: "Mozilla",
          identity: "Netscape",
          versionSearch: "Mozilla"
        }
      ],
      dataOS : [
        {
          string: navigator.platform,
          subString: "Win",
          identity: "Windows"
        },
        {
          string: navigator.platform,
          subString: "Mac",
          identity: "Mac"
        },
        {
             string: navigator.userAgent,
             subString: "iPhone",
             identity: "iPhone/iPod"
          },
        {
          string: navigator.platform,
          subString: "Linux",
          identity: "Linux"
        }
      ]

    };`
  

  # profile - setup the limits of the current system we are on
  _profile : () ->
    
    @profile = {}  

    @profile.antialias = @gl.getContextAttributes().antialias
    @profile.aa_size = @gl.getParameter @gl.SAMPLES
    highp = @gl.getShaderPrecisionFormat(@gl.FRAGMENT_SHADER, @gl.HIGH_FLOAT)
    @profile.highpSupported = highp.precision != 0
    @profile.maxTexSize = @gl.getParameter(@gl.MAX_TEXTURE_SIZE)
    @profile.maxCubeSize = @gl.getParameter(@gl.MAX_CUBE_MAP_TEXTURE_SIZE)
    @profile.maxRenderbufferSize = @gl.getParameter(@gl.MAX_RENDERBUFFER_SIZE)
    @profile.vertexTextureUnits = @gl.getParameter(@gl.MAX_VERTEX_TEXTURE_IMAGE_UNITS)
    @profile.fragmentTextureUnits = @gl.getParameter(@gl.MAX_TEXTURE_IMAGE_UNITS)
    @profile.combinedUnits = @gl.getParameter(@gl.MAX_COMBINED_TEXTURE_IMAGE_UNITS)
    @profile.maxVSattribs = @gl.getParameter(@gl.MAX_VERTEX_ATTRIBS)
    @profile.maxVertexShaderUniforms = @gl.getParameter(@gl.MAX_VERTEX_UNIFORM_VECTORS)
    @profile.maxFragmentShaderUniforms = @gl.getParameter(@gl.MAX_FRAGMENT_UNIFORM_VECTORS)
    @profile.maxVaryings = @gl.getParameter(@gl.MAX_VARYING_VECTORS)
    @profile.extensions = @gl.getSupportedExtensions()
    @profile.maxBufferSize = 65536

    # Just to make sure we are in a browser before we perform this
    if navigator?
      BrowserDetect.init();

      @profile.browser = BrowserDetect.browser
      @profile.os = BrowserDetect.OS
      @profile.version = BrowserDetect.version

      # Look for extensions that we like
      # TODO - Maybe allow these to be passed in as params? Maybe not?
      # These are here because we make use of them quite a bit

      se = @gl.getSupportedExtensions()

      @profile.extensions = []

      if 'OES_standard_derivatives' in se
        @profile.extensions.push 'OES_standard_derivatives'
        @gl.getExtension 'OES_standard_derivatives'

      if 'OES_texture_float' in se
        @profile.extensions.push 'OES_texture_float'
        @gl.getExtension 'OES_texture_float'

      # http://stackoverflow.com/questions/11381673/javascript-solution-to-detect-mobile-browser

      `function detectmob() { 
        if( navigator.userAgent.match(/Android/i)
        || navigator.userAgent.match(/webOS/i)
        || navigator.userAgent.match(/iPhone/i)
        || navigator.userAgent.match(/iPad/i)
        || navigator.userAgent.match(/iPod/i)
        || navigator.userAgent.match(/BlackBerry/i)
        || navigator.userAgent.match(/Windows Phone/i)
        ){
          return true;
        }
        else {
          return false;
        }
      }`
    
      @profile.mobile = detectmob()

      console.log @profile


  # run - called by the frame function
  run : () =>
    if @_pause
      return

    if  @_framescounter > 0
      @_framescounter--

      if @_framescounter <= 0
        @pause true

    @_draw @getDelta() 
   

  # Pause / un-psue the draw and update loops if needed. force is a boolean and is optional
  pause : (force) ->
    if not force?
      @_pause = !@_pause 
    else
      @_pause = force

    if not @_pause
      @startTime = Date.now()
      @oldTime = @startTime
      @canvas.focus() # Gain the focus so we can process keyboard events

    # Stop / start emitting events
    @pauseKeyEmitter @_pause
    @pauseTouchEmitter @_pause
    @pauseMouseEmitter @_pause
    @

  
  # getDelta - Returns the dt value in milliseconds
  getDelta : () =>

    deltaTime = Date.now() - @oldTime
    @oldTime = Date.now()
    return deltaTime

  switchContext : (context) ->
    if context?
      PXL.Context = context
      window.GL = context.gl if window?
    else 
      if PXL.Context != @
        PXL.Context = @ # Global GL Function for our contexts
        window.GL = @gl if window?
    @

  # Called by the surrounding application javascript should you wish
  resizeCanvas: (width, height) ->
    @switchContext()

    if @canvas
      if @gl
        @width = width
        @height = height
        @canvas.width = width
        @canvas.height = height
    @

  # _draw - Internal draw function. Calls the user's draw function if provided
  _draw: (dt) ->
    @contextTime = Date.now() - @startTime
    @switchContext()
    if @draw?
      @draw.call @app_context, dt

 
  # Stop running the loops and destroy the context
  shutdown : () ->
    @pause true

    @user_shutdown.call @app_context if @user_shutdown?

    # Remove emitters
    removeMouseEmitter @
    removeTouchEmitter @
    removeKeyEmitter @

    @

    # TODO - Perform some kind of deletion / garbage collection

module.exports =
  App : App

