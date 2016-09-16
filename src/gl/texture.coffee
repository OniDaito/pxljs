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


TODO - Probably pass in data and have a convinence method that calls a request?
  - handling no RGBA textures like JPGS?

https://developer.mozilla.org/en-US/docs/WebGL/Animating_textures_in_WebGL


Texture Objects - uses the request object and callbacks. Is bound to a context

- TODO
  * How does this match with textures in the current shader context? Check that!
  * Video textures and compressed textures as per the spec for HTML5

###

{Request} = require '../util/request'

{PXLError, PXLWarning, PXLLog} = require '../util/log'

{Contract} = require '../gl/contract'

### TextureBase ###
# Our base texture. It creates a blank set of data bound to a texture

class TextureBase

  @UNITS = [] # Which texture unit is free?

  # **@constructor**
  # - **params** - an Object with named members as follows
  # -- **min** - a GL_ENUM - Default GL.LINEAR
  # -- **max** - a GL_ENUM - Default GL.LINEAR
  # -- **wraps** - a GL_ENUM - Default GL.CLAMP_TO_EDGE
  # -- **width** - a Number - Default 512
  # -- **height** - a Number - Default 512
  # -- **channels** - a GL_ENUM - Default GL.RGBA
  # -- **datatype** - a GL_ENUM - Default GL.UNSIGNED_BYTE
  
  constructor : (params) ->

    if not PXL.Context.gl?
      PXLError("No context or url provided for texture")

    gl = PXL.Context.gl
    if not params?
      params = {}

    # Build our @UNITS if it isnt already? This is perhaps not optimal
    # but rather than do this in the App class I prefer to do it here

    # Watcher for texture bind units
    if TextureBase.UNITS.length == 0
      for i in [0..PXL.Context.profile.combinedUnits-1]
        TextureBase.UNITS.push null


    # Non power of two textures must have the following in webgl
    # TODO - test for powers and look at params

    @unit = 0  # unit is 0 - default
    @min =  if not params.min? then gl.LINEAR else params.min
    @max =  if not params.max? then gl.LINEAR else params.max
    @wraps = if not params.wraps? then gl.CLAMP_TO_EDGE else params.wraps
    @wrapt =  if not params.wrapt? then gl.CLAMP_TO_EDGE else params.wrapt
    @width = if not params.width? then 512 else params.width
    @height = if not params.height? then 512 else params.height
    @channels = if not params.channels? then gl.RGBA else params.channels 
    @datatype = if not params.datatype? then gl.UNSIGNED_BYTE  else params.datatype


    @texture = gl.createTexture()

    @contract = new Contract()
    @contract.roles.uSampler = "unit" # Default role for a texture - overridden in materials

  _isPowerOfTwo : (x) ->
    return (x & (x - 1)) == 0

  # Internal static lookup - tries to find empty texture units
  _findUnit : () ->
    for i in [0..TextureBase.UNITS.length-1]
      if TextureBase.UNITS[i] == null or TextureBase.UNITS[i] == @
        TextureBase.UNITS[i] = @
        return i
    
    PXLError "Run out of available texture units"
    0


  _nextHighestPowerOfTwo : (x) ->
    --x
    i = 1
    while i < 32
      x = x | x >> i
      i <<= 1
   
    return x + 1

  # **build** - create the actual texture on the GPU
  # - returns this
  build : () ->
    context = PXL.Context
    gl = context.gl
    
    @bind()

    # TODO - using channels twice here - thats not strictly true and will need adjusting
    gl.texImage2D(gl.TEXTURE_2D,0, @channels, @width, @height, 0, @channels, @datatype ,null)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, @max)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, @min)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, @wraps)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, @wrapt)
    
    @unbind()

    @loaded = true

    @

  # **bind** - bind this texture to texture unit in params (or the one given in unit)
  # - **unit** - a Number - Integer
  # - returns this
  bind: (unit) ->
    
    gl = PXL.Context.gl
    if unit?
      @unit = unit
    else if gl?
      @unit = @_findUnit()
    
    gl.activeTexture GL.TEXTURE0 + @unit
    gl.bindTexture(gl.TEXTURE_2D, @texture)
    @
      
  # **unbind** - clear the bound unit
  # - returns this
  unbind: ->
    gl = PXL.Context.gl
    if gl?
      gl.activeTexture(gl.TEXTURE0 + @unit)
      gl.bindTexture(gl.TEXTURE_2D, null)
      TextureBase.UNITS[@unit] = null
      @unit = 0
    @

  # **update** - update the data of the texture. If we are referencing an image or video (like HTML5 image) then
  # simply re-read the image. If we are using a data texture however, this new array is 
  # passed in as an array of values like [0,1,0,1,1] etc and converted
  # TODO do we really need to bind here in order to update a texture? Check that! 
  # Example, in the case of a skeleton pallete we bind, update, then unbind only to bind again
  # - **texdata** - an Image, Array, Uint8Array, Float32Array - Required

  update : (texdata) ->
    
    if @textureData instanceof Image and not texdata?

      gl = PXL.Context.gl
      
      @bind()
      gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL, false)
      gl.texImage2D(gl.TEXTURE_2D, 0, @channels, @channels, @datatype, @textureData)
      @unbind()

    else if texdata? and texdata instanceof Array

      # We do the conversion here I think

      if  @datatype == GL.UNSIGNED_BYTE
        @textureData = new Uint8Array texdata

      else if @datatype == GL.FLOAT
        @textureData = new Float32Array texdata

      gl = PXL.Context.gl
      @bind()
      gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL, false)
      gl.texImage2D(gl.TEXTURE_2D, 0, @channels, @width, @height, 0, @channels, @datatype, @textureData)
      @unbind()

    else if texdata? and (texdata instanceof Uint8Array or texdata instanceof Float32Array)
      @textureData = texdata
      
      gl = PXL.Context.gl
      @bind()
      gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL, false)
      gl.texImage2D(gl.TEXTURE_2D, 0, @channels, @width, @height, 0, @channels, @datatype, @textureData)
      @unbind()

  # _addToNode - called when this texture is added to a node
  _addToNode: (node) ->
    node.textures.push @
    @

  # _removeFromNode - called when this texture is removed from a node
  _removeFromNode: (node) ->
    node.textures.splice node.textures.indexOf @
    @
  
  # **washUp** - remove from the graphics card
  washup : () ->
    gl = PXL.Context.gl
    gl.deleteTexture @texture
    @


### Texture ###
# Create a texture from either a provided image or creates a blank one if texdata not provided
# Params are as the TextureBase class

class Texture extends TextureBase

  # **@constructor**
  # - **texdata** - an Image, Array, Uint8Array or Float32Array - Required
  # - **params** - an Object with named members as follows:
  # -- **min** - a GL_ENUM - Default GL.LINEAR
  # -- **max** - a GL_ENUM - Default GL.LINEAR
  # -- **wraps** - a GL_ENUM - Default GL.CLAMP_TO_EDGE
  # -- **width** - a Number - Default 512
  # -- **height** - a Number - Default 512
  # -- **channels** - a GL_ENUM - Default GL.RGBA
  # -- **datatype** - a GL_ENUM - Default GL.UNSIGNED_BYTE
  constructor: (texdata, params) ->
    super(params)

    if not PXL.Context.gl?
      PXLError("No context provided for texture")

    if texdata?
      if texdata instanceof Image
        @textureData = texdata  
        @width = @textureData.width
        @height = @textureData.height
  
      else if texdata instanceof Array
        if  @datatype == GL.UNSIGNED_BYTE
          @textureData = new Uint8Array texdata

        else if @datatype == GL.FLOAT
          @textureData = new Float32Array texdata

      else if texdata instanceof Uint8Array or texdata instanceof Float32Array
        @textureData = texdata

    else
      PXLLog "No Texture Data provided. Assuming uint8 data"
      
      texdata = []
      
      for i in [0..@width*@height*@channels-1]
        texdata.push 0
      
      @textureData = new Float32Array texdata
     
    @build()


  # **build** - actually create the texure on the GPU
  # - returns this
  build : () ->
    context = PXL.Context
    gl = context.gl
    # TODO are we sure we dont need to flip anymore
    gl.pixelStorei gl.UNPACK_FLIP_Y_WEBGL, false
    gl.bindTexture gl.TEXTURE_2D, @texture

    # In case we are using webgl images and or video as oppose to our array for messing with
    if @textureData instanceof Image
      gl.texImage2D gl.TEXTURE_2D, 0, @channels, @channels, @datatype, @textureData
    else
      gl.texImage2D gl.TEXTURE_2D, 0, @channels, @width, @height, 0, @channels, @datatype, @textureData

    gl.texParameteri gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, @min
    gl.texParameteri gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, @max
    gl.texParameteri gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, @wraps
    gl.texParameteri gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, @wrapt

    gl.bindTexture gl.TEXTURE_2D, null
    @

### textureFromURL ###
# Load a texture from a URL - convinience function that wraps a request
# Takes a url string, a callback, a failure callback. and optional params
# Saves the current context so we can fire different context requests
# TODO - Ideally we would have a future here and block till it returns?
# - **url** - a String - Required
# - **callback** - a Function with the following params
# -- **texture** - a Texture
# - **onerror** - a Function
# - **params** - an Object with the following named members:
# -- **min** - a GL_ENUM - Default GL.LINEAR
# -- **max** - a GL_ENUM - Default GL.LINEAR
# -- **wraps** - a GL_ENUM - Default GL.CLAMP_TO_EDGE
# -- **width** - a Number - Default 512
# -- **height** - a Number - Default 512
# -- **channels** - a GL_ENUM - Default GL.RGBA
# -- **datatype** - a GL_ENUM - Default GL.UNSIGNED_BYTE
  
textureFromURL = (url, callback, onerror, params) ->

    if not url? or not PXL.Context.gl?
      PXLWarning "No context or url provided for texture"

    cc = PXL.Context
    gl = cc.gl

    # TODO - On these callbacks context needs to be saved each time
    # from the request all the way down :S

    r = new Request url

    success = () =>
      texImage = new Image()
      texImage.src = url

      loadHandler = () =>

        texture = new Texture texImage, params
        callback?(texture)

      texImage.addEventListener('load', loadHandler)
      
      if texImage.complete
        loadHandler()

    failure = () =>
      PXLWarning "Failed to load Texture: " + url
      onerror?()

    r.get success, failure
       
### TextureCube ###
# Loads 6 textures for the texture cube.


class TextureCube extends TextureBase
  # **@constructor**
  # - **images** - an Array of Image - size 6 
  # - **params** - an Object with the following members
  # -- **min** - a GL_ENUM - Default GL.LINEAR
  # -- **max** - a GL_ENUM - Default GL.LINEAR
  # -- **wraps** - a GL_ENUM - Default GL.CLAMP_TO_EDGE
  # -- **width** - a Number - Default 512
  # -- **height** - a Number - Default 512
  # -- **channels** - a GL_ENUM - Default GL.RGBA
  # -- **datatype** - a GL_ENUM - Default GL.UNSIGNED_BYTE
  
  constructor: (images, params) ->
    
    super (params)

    gl = PXL.Context.gl

    gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL, false)
    gl.bindTexture(gl.TEXTURE_CUBE_MAP,@texture)

    gl.texParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_MAG_FILTER, @max);
    gl.texParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_MIN_FILTER, @min);
    gl.texParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_WRAP_S, @wraps);
    gl.texParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_WRAP_T, @wrapt);

    for j in [0..5]
      gl.texImage2D(gl.TEXTURE_CUBE_MAP_POSITIVE_X + j, 0, @channels, @channels, @datatype, images[j]);

    gl.bindTexture(gl.TEXTURE_CUBE_MAP, null);

  # **bind** - bind this texture to texture unit given in params (or the one given in unit)
  # - **unit** - a Number - Integer
  # - returns this
  bind: (unit) ->
   
   gl = PXL.Context.gl
   if unit?
      @unit = unit
   else if gl?
      @unit = @_findUnit()
    
    gl.activeTexture(gl.TEXTURE0 + @unit)
    gl.bindTexture(gl.TEXTURE_CUBE_MAP, @texture)
      
  # **unbind** - clear the bound unit
  # - returns this
  unbind: ->
    gl = PXL.Context.gl
    if gl?
      gl.activeTexture(gl.TEXTURE0 + @unit)
      gl.bindTexture(gl.TEXTURE_CUBE_MAP, null)
      TextureBase.UNITS[i] = null
      @unit = 0
    @

### textureCubeFromURL ###
# - **paths** - an Array of String - Length 6 - Required
# - **callback** - a Function with the following params
# -- **texture** - a TextureCube
# - **onerror** - a Function
# - **params** - an Object with the following named members:
# -- **min** - a GL_ENUM - Default GL.LINEAR
# -- **max** - a GL_ENUM - Default GL.LINEAR
# -- **wraps** - a GL_ENUM - Default GL.CLAMP_TO_EDGE
# -- **width** - a Number - Default 512
# -- **height** - a Number - Default 512
# -- **channels** - a GL_ENUM - Default GL.RGBA
# -- **datatype** - a GL_ENUM - Default GL.UNSIGNED_BYTE
# - returns this
textureCubeFromURL = (paths,callback,onerror,params) ->

  if not paths? or not PXL.Context?
    PXLError("No context or urls provided for cubemap texture")

  if paths.length != 6
    PXLError("6 URLs must be provided for cubemap texture")

  texImages = []
  loadedTextures = 0

  cc = PXL.Context

  for i in [0..5]
    texImages[i] = new Image()
    texImages[i].cubeID = i
    texImages[i].src = paths[i]

    texImages[i].onload = () =>

      loadedTextures++
      if loadedTextures == 6

        texture = new TextureCube texImages, params
        callback?(texture)
  @

module.exports =
  Texture : Texture
  TextureBase : TextureBase
  TextureCube : TextureCube
  textureFromURL : textureFromURL
  textureCubeFromURL : textureCubeFromURL
