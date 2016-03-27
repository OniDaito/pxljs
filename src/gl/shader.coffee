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

###


{Matrix4, Vec2, Vec3, Vec4} = require '../math/math'
{Light} = require '../light/light'
{PXLError, PXLWarning, PXLLog} = require '../util/log'
{Contract} = require './contract'


### Shader ###
# The master shader class. Represents a shader that can be bound to a context or attached to a node
# chunks - a list [] of ShaderChunks that create our shader - order is important - it defines what
# chunks take precidence. chunks later on in the line rely and may overwrite these earlier in line.
# user_roles = passed onto the contract 

class Shader

  # Constructor. Designed so an object can be built with no parameters 
  # via functions such as shaderFromText
  # We keep hold of the chunks incase we need to rebuild the shader (changing various defines 
  # for example)

  constructor : (@vertex_source, @fragment_source, user_roles) ->

    if PXL?
      if PXL.Context.gl?
        @_compile @vertex_source, @fragment_source
        @contract = new Contract( @_getAttributes(), @_getUniforms(), user_roles)

    @_uber = false
    @

  _compile: (sv, sf) ->
    gl = PXL.Context.gl # Global / Current context
    
    # Create the Vertex Shader
    @vertexShader = gl.createShader(gl.VERTEX_SHADER);
    if not @vertexShader
      PXLError "No vertex shader object could be created"

    # Fragment Shader 
    
    @fragmentShader = gl.createShader(gl.FRAGMENT_SHADER)
 
    if not @fragmentShader
      PXLError "No Fragment shader object could be created"

    gl.shaderSource @vertexShader, sv
    gl.compileShader @vertexShader

    if not gl.getShaderParameter @vertexShader, gl.COMPILE_STATUS  
      @_printLog @vertexShader, sv, "vertex"

    gl.shaderSource @fragmentShader, sf
    gl.compileShader @fragmentShader

    if not gl.getShaderParameter @fragmentShader, gl.COMPILE_STATUS
      @_printLog @fragmentShader, sf, "fragment"

    @shaderProgram = gl.createProgram()

    gl.attachShader(@shaderProgram, @vertexShader)
    gl.attachShader(@shaderProgram, @fragmentShader)
    
    # Naughty hack - we check for the attribute aVertexPosition to bind it to 0!
    # TODO - might need to do something better here but it stops attrib 0 being blank which is good
    gl.bindAttribLocation(@shaderProgram, 0, "aVertexPosition")

    gl.linkProgram(@shaderProgram)

    success = gl.getProgramParameter(@shaderProgram, gl.LINK_STATUS)
    if not success
      PXLWarning gl.getProgramInfoLog @shaderProgram
      PXLError "Failed to Link Shader"

      WebGLActiveInfo

    # We grab the attributes here and we set their positions to these
    # in the contract - order dependent
    # Thanks to @Tojiro

    attrs = @_getAttributes()
    for attr in attrs
      gl.bindAttribLocation @shaderProgram, attr.pos, attr.name

    @

  _printLog : (shader, source, kind) ->
    compilationLog = PXL.Context.gl.getShaderInfoLog shader
    PXLLog 'Shader compiler log: ' + compilationLog
    tsf = ""
    ln = 1
    
    for l in source.split "\n"
      tsf += ln + ": " + l + "\n"
      ln++

    PXLLog tsf
    @_splitError compilationLog, source
    PXLError "Could not compile " + kind + " shader"

  _addToNode : (node) ->
    node.shader = @
    @

  _splitError : (s, data) ->
    lines = s.split('\n')
    for line in lines
      match = line.match(/ERROR: (\d+):(\d+): (.*)/)
      if match
        fileno = parseInt(match[1],10)-1
        lineno = parseInt(match[2],10)-1
        message = match[3]

        datalines = data.split('\n')

        PXLLog "Shader Error Log: " + fileno + ", " + lineno + ", " + message + "," + datalines[lineno]
    @

  # _getLocation: Return the location of a variable inside a compiled shader
  _getLocation : (name) ->
    PXL.Context.gl.getUniformLocation(@shaderProgram, name)

  # bind - bind the shader to the current context
  bind: ->
    PXL.Context.gl.useProgram(@shaderProgram);
    PXL.Context.shader = @
    @

  # unbind - Clear the current context so there are no shaders
  unbind: ->
    PXL.Context.gl.useProgram(null)
    @


  # washUp - Remove this shader and destroy it
  washUp : ->
    gl = PXL.Context.gl
    gl.detachShader(@shaderProgram, @vertexShader)
    gl.detachShader(@shaderProgram, @fragmentShader)

    gl.deleteProgram(@shaderProgram)
    gl.deleteShader(@vertexShader)
    gl.deleteShader(@fragmentShader)
    
    @

  _getAttributes : () ->

    # Cache attributes as they hopefully wont change!
    if not @attributes?
      gl = PXL.Context.gl
      num_attributes = gl.getProgramParameter @shaderProgram, GL.ACTIVE_ATTRIBUTES
      @attributes = []

      # we set and use the positions here. aVertexPosition must always be zero
      for i in [0..num_attributes-1]

        a = gl.getActiveAttrib @shaderProgram, i
        
        attribute = 
          name : a.name
          pos : gl.getAttribLocation(@shaderProgram, a.name)
          type : a.type # TODO - test this
          size : a.size # Pretty much always 1 it seems for attributes
      
        @attributes.push attribute

    @attributes


  # _getUniforms - Find all the active uniforms in a shader
  # returns a list of objects :
  # { name, type, pos, size }
  # Types are listed thusly and will need to be changed
  # /* Uniform Types */
  ###
    const GLenum FLOAT_VEC2                     = 0x8B50; 
    const GLenum FLOAT_VEC3                     = 0x8B51;
    const GLenum FLOAT_VEC4                     = 0x8B52;
    const GLenum INT_VEC2                       = 0x8B53;
    const GLenum INT_VEC3                       = 0x8B54;
    const GLenum INT_VEC4                       = 0x8B55;
    const GLenum BOOL                           = 0x8B56;
    const GLenum BOOL_VEC2                      = 0x8B57;
    const GLenum BOOL_VEC3                      = 0x8B58;
    const GLenum BOOL_VEC4                      = 0x8B59;
    const GLenum FLOAT_MAT2                     = 0x8B5A;
    const GLenum FLOAT_MAT3                     = 0x8B5B;
    const GLenum FLOAT_MAT4                     = 0x8B5C;
    const GLenum SAMPLER_2D                     = 0x8B5E;
    const GLenum SAMPLER_CUBE                   = 0x8B60;
  ###

  _getUniforms : () ->
    # Cache uniforms as they hopefully wont change!
    if not @uniforms?
      gl = PXL.Context.gl

      num_uniforms = gl.getProgramParameter @shaderProgram, GL.ACTIVE_UNIFORMS

      @uniforms = []

      for i in [0..num_uniforms-1]

        u = gl.getActiveUniform @shaderProgram, i

        # It appears that active uniform arrays seem to have their name with '[0]' so remove
        # TODO - must check to make sure this is the actual behaviour
        tn = u.name
        i = tn.indexOf("[")
        if i > 0
          tn = u.name.slice(0,i)

        uniform = 
          name : tn 
          pos : @._getLocation u.name
          type : u.type # TODO - test this
          size : u.size # TODO - test this

        @uniforms.push uniform

    @uniforms

  # _getTextures - find all the texture in a shader
  # TODO - other samplers? Texture Cube for example?
  _getTextures : () ->
    d = @._parseShader("uniform")
    x = []
    for a in d
      if a.type == "sampler2D"
        p = @._getLocation(a.name)
        if p? and p != -1
          a.pos = p
          x.push(a)
    x

   # _parseShader - Given a token, a line basically, parse the line and get the types (vec3 etc)
  _parseShader : (token) ->
    data = []
    lines = @sv.split(";").concat(@sf.split(";"));
    for l in lines
      re = RegExp("\\b" + token + "\\b"); 
      if l.match(re)?
        tokens  = l.split(" ")
        finals = []

        for t in tokens
          t = t.replace /\n/, ""
          t = t.replace /\s/, ""

          if t.length != 0
            finals.push t

        finals.push 1
        matches = finals[2].match(/\[([0-9]+)\]/)
     
        if matches?
          finals[3] = matches[1]

        finals[2] = finals[2].match(/([a-zA-Z]+)/g)[0]

        if finals.length == 4
          attr = {}
          attr.name = finals[2]
          attr.type = finals[1]
          attr.pos = -1
          attr.size = finals[3]
          data.push attr 

    data


  # setUniform1f - Given a uniform name and one float, set this uniform
  setUniform1f: (name,a) ->
    gl = PXL.Context.gl
    gl.uniform1f(@_getLocation(name),a)
    @

  # setUniform1i - Given a uniform name and one integer, set this uniform
  setUniform1i: (name,a) ->
    gl = PXL.Context.gl
    gl.uniform1i(@_getLocation(name),a)
    @

  # setUniform1fv - Given a uniform name and an array of floats, not grouped, set this uniform
  setUniform1fv : (name, a) ->
    gl = PXL.Context.gl
    gl.uniform1fv(@_getLocation(name), a)
    @

  # setUniform2fv - Given a uniform name and an array of floats, grouped in pairs, set this uniform
  setUniform2fv : (name, a) ->
    gl = PXL.Context.gl
    gl.uniform2fv(@_getLocation(name), a)
    @

  # setUniform2v - Given a uniform name and a Vec2, set this uniform
  setUniform2v: (name,v) ->
    gl = PXL.Context.gl
    gl.uniform2f(@_getLocation(name),v.x,v.y)
    @

  # setUniform3f - Given a uniform name and three floats, set this uniform
  setUniform3f: (name,a,b,c) ->
    gl = PXL.Context.gl
    gl.uniform3f(@_getLocation(name),a,b,c)
    @

  # setUniform3fv - Given a uniform name and an array of floats, grouped in threes, set this uniform
  setUniform3fv : (name, a) ->
    gl = PXL.Context.gl
    gl.uniform3fv(@_getLocation(name), a)
    @


  # setUniform3v - Given a uniform name and a Vec3, set this uniform
  setUniform3v: (name,v) ->
    gl = PXL.Context.gl
    gl.uniform3f(@_getLocation(name),v.x,v.y,v.z)
    @ 

  # setUniform3f - Given 3 floats, set this uniform
  setUniform3f: (name,a,b,c) ->
    gl = PXL.Context.gl
    gl.uniform3f(@_getLocation(name),a,b,c)
    @ 

  # setUniform4f - Given a uniform name and four floats, set this uniform
  setUniform4f: (name,a,b,c,d) ->
    gl = PXL.Context.gl
    gl.uniform4f(@_getLocation(name),a,b,c,d) 
    @


  # setUniform4v - Given a uniform name and a Vec4, set this uniform
  setUniform4v: (name,v) ->
    gl = PXL.Context.gl
    gl.uniform4f(@_getLocation(name),v.x,v.y,v.z,v.w)
    @ 

  # setUniform4fv - Given a uniform name and an array of floats, grouped in fours, set this uniform
  setUniform4fv : (name, a) ->
    gl = PXL.Context.gl
    gl.uniform4fv(@_getLocation(name), a)
    @


  # setMatrix4f - Given a uniform name and a matrix4, set this uniform
  setMatrix3f: (name, m) ->
    gl = PXL.Context.gl
    gl.uniformMatrix3fv(@_getLocation(name), false, m.a)
    @

  # setMatrix4f - Given a uniform name and a matrix4, set this uniform
  setMatrix4f: (name, m) ->
    gl = PXL.Context.gl
    gl.uniformMatrix4fv(@_getLocation(name), false, m.a)
    @

  # enableAttribArray - Enable an attribute array by name
  enableAttribArray: (name) ->
    gl = PXL.Context.gl
    position = gl.getAttribLocation(@shaderProgram, name)
    gl.enableVertexAttribArray(position)
    @

  # getAttribLocation - Get the location of an attribute
  getAttribLocation: (name) ->
    gl = PXL.Context.gl
    gl.getAttribLocation(@shaderProgram, name)


### shaderFromText ###
# Create a shader from a block of text and an optional contract

shaderFromText = ( text, contract ) ->

  _splitShader = (s) ->
    
    sv = sf = ""

    pv = s.indexOf("##>VERTEX")
    pf = s.indexOf("##>FRAGMENT")
   
    # Grab vertex section
    if pv != -1
      if pf != -1 and pf > pv
        sv = s.slice(pv + 9, pf)
      else if pf != -1 and pf < pv
        sv = s.slice(pv + 9)

    # Grab fragment section
     if pf != -1
      if pv != -1 and pv > pf
        sf = s.slice(pf + 11, pv)
      else if pf != -1 and pv < pf
        sf = s.slice(pf + 11)
   
    [sv,sf]


  _matchWithLibrary = (s) ->
    matches = s.match(/\{\{(ShaderChunkLibrary\.[a-zA-Z]+)\}\}/g)
  
    chunks = []
    
    if matches?
      for  match in matches
        type = match.replace("}}","").split(".")[1]
        if not ShaderChunkLibrary[type]?
          #s = s.replace match,""
          PXLError "Could not find " + type + " in Shader Library"

        else #if ShaderChunkLibrary[type][shader_type]?
          #if ShaderChunkLibrary[type][shader_type]["head"]?
          #  s = s.replace match, ShaderChunkLibrary[type][shader_type]["head"]
         
          #if ShaderChunkLibrary[type][shader_type]["main"]?
          #  main_block += ShaderChunkLibrary[type][shader_type]["main"] + "\n"
          #else
          #   s = s.replace match,""

          chunks.push ShaderChunkLibrary[type]

    chunks

  _findPrecision = (s) ->
    pp = ""
    pv = ps = s.indexOf("precision")
    pe = -1
    while pv != -1
      pe = s.indexOf(";",pv)
      pp += s.slice(pv, pe + 1) + "\n"
      pv = s.indexOf("precision",pe)
    
    # Remove the blocks of precision
    if ps != -1
      s = s.slice(pe+1)

    [pp,s]

   _findMain = (s) ->
    ps = s.indexOf("void main")
    if ps != -1
      # Assume the main function is the last thing in the shader :)
      return [ s.slice(ps), s.slice(0,ps)]

    [undefined,s]

  [sv,sf] = _splitShader text

  chunks = _matchWithLibrary text

  sv = sv.replace /;(?! [a-zA-Z0-9])/g, ';'
  sv = sv.replace /\{/g, '{'
  sv = sv.replace /\}/g, '}'
 
  sf = sf.replace /;(?! [a-zA-Z0-9])/g, ';'
  sf = sf.replace /;(?! [a-zA-Z0-9])/g, ';'
  sf = sf.replace /\{/g, '{'
  sf = sf.replace /\}/g, '}'

  # Make a chunk out of the remaining sv and sf

  [precision_fragment,sf] = _findPrecision sf
  [precision_vertex,sv] = _findPrecision sv

  [main_fragment,sf] = _findMain sf
  [main_vertex,sv] = _findMain sv

  chunks.push new ShaderChunk {func : sv, main_func : main_vertex}, {func : sf, main_func : main_fragment}

  shader = new Shader chunks, contract, precision_vertex, precision_fragment
 
  shader


module.exports = 
  Shader : Shader
  shaderFromText : shaderFromText