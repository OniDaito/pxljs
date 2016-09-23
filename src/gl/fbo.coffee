###
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


Framebuffer objects - reads the current active context from the exports and creates a FBO

Basic FBO with depth, linear filtering and RGBA with unsigned bytes

Remember, NPOT textures are support but not with repeats or mipmapping

- TODO
  * Depth options

###

{PXLError, PXLDebug} = require '../util/log'
{RGB,RGBA} = require '../colour/colour'
{Vec2} = require '../math/math'
{TextureBase} = require './texture'


# ## Fbo
# A class for Framebuffer objects
# Simply provide the the constructor variables and then bind in order to draw to this

class Fbo
  # **constructor** - 
  # - **width** - a Number
  # - **height** - a Number
  # - **channels** - gl.R, gl.RGB, gl.RGBA or similar, optional, default gl.RGBA
  # - **datatype** - gl.UNSIGNED_BYTE or similar, optional, default gl.UNSIGNED_BYTE
  # - **depth** - a boolean, optional, default true
  constructor: (@width, @height, @channels, @datatype, @depth) ->
    gl = PXL.Context.gl

    if not (@width? and @height?)
      @width =  PXL.Context.width
      @height =  PXL.Context.height

    @channels= gl.RGBA if not @channels?
    @datatype = gl.UNSIGNED_BYTE if not @datatype?
    @depth = true if not @depth?

    @framebuffer = gl.createFramebuffer()

    PXLDebug "Created an FBO  with dimensions: " + @width + "," + @height

    @_build()
  
  # **resize** - Given width and height (as either a Vec2 or two seperate numbers), resize this FBO
  # - **w** - a Number - Integer - Reequired
  # - **h** - a Number - Integer - Reequired
  # - returns this
  resize: (w,h) ->

    if w instanceof Vec2
      @width = w.x
      @height = w.y

    else if w? and h? 
      @width = w
      @height = h
    else 
      return @

    @_build()
    @

  # _build - internal function that actually creates the Fbo
  _build : () ->

    gl = PXL.Context.gl
    gl.bindFramebuffer(gl.FRAMEBUFFER,@framebuffer)
 
    if not @texture?
      params =
        "min" : gl.LINEAR
        "max" : gl.LINEAR
        "wraps" : gl.CLAMP_TO_EDGE
        "wrapt" : gl.CLAMP_TO_EDGE
        "width" : @width
        "height" : @height
        "channels" : @channels
        "datatype" : @datatype 

      @texture = new TextureBase(params)
      @texture.build()
    else
      @texture.bind()
      gl.texImage2D(gl.TEXTURE_2D,0, @channels, @width, @height, 0, @channels, @datatype ,null)
        

    @renderbuffer = gl.createRenderbuffer()
    
    gl.bindRenderbuffer(gl.RENDERBUFFER,@renderbuffer)
    gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, @texture.texture, 0)
    
    if @depth
      gl.renderbufferStorage(gl.RENDERBUFFER, gl.DEPTH_COMPONENT16, @width, @height)
      gl.framebufferRenderbuffer(gl.FRAMEBUFFER, gl.DEPTH_ATTACHMENT, gl.RENDERBUFFER, @renderbuffer)
    
    gl.bindRenderbuffer(gl.RENDERBUFFER,null)
    gl.bindFramebuffer(gl.FRAMEBUFFER,null)
    @texture.unbind()

    if gl.checkFramebufferStatus(gl.FRAMEBUFFER) != gl.FRAMEBUFFER_COMPLETE
      PXLError "Failed to Create Framebuffer!"


  # **bind** - Bind this fbo to the current drawing context
  # - returns this
  bind : () ->
    gl = PXL.Context.gl
    
    gl.bindFramebuffer(gl.FRAMEBUFFER,@framebuffer)
    gl.bindRenderbuffer(gl.RENDERBUFFER,@renderbuffer)
    @

  # **unbind** - remove this fbo from the context
  # - returns this
  unbind: () ->
    gl = PXL.Context.gl
    gl.bindFramebuffer(gl.FRAMEBUFFER,null)
    gl.bindRenderbuffer(gl.RENDERBUFFER,null)
    @

  # **clear** - Clear the FBO with an optional colour
  # - **colour** - a Colour
  # - returns this
  clear : (colour) ->
    gl = PXL.Context.gl
    
    if not colour?
      gl.clearColor(0.0, 0.0, 0.0, 0.0)
    else
      if colour instanceof RGBA
        gl.clearColor(colour.r, colour.g, colour.b, colour.a)
      else if colour instanceof RGB
        gl.clearColor(colour.r, colour.g, colour.b, 1.0)
    
    if @depth
      gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
    else
      gl.clear gl.COLOR_BUFFER_BIT
    
    @

  # **washUp** - delete this Fbo from the Graphics Card
  # - returns this
  washUp : () ->
    gl = PXL.Context.gl
    gl.deleteFramebuffer(@framebuffer)
    gl.deleteRenderbuffer(@renderbuffer)
    gl.deleteTexture(@texture.texture)
    @
  
module.exports = 
  Fbo : Fbo
