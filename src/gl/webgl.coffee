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


The WebGL End of our basic primitives. Here we match our classes to the WebGL Shaders 
and buffers

 - TODO
  * We are creating Float32Arrays on the fly. Fine, but we should possibly
    hold onto these buffers and index into them, replacing geometry memory? I.e
    each vertex data bit points to its position in the Float32Array? Could be expensive
    Shapes or trimeshes could in fact do that I think.
  * Geometry may or may not have more buffers (should we wish to add them)
  * Do we put in face duplication here? I.e, if we want to pass in per face details
    we need to change the buffers
  * It appears that bufferSubData isnt the thing to use but is this true? (for updateing)
  * Geometry that has changed totally? Delete and redo buffers is needed
  * Per Face Brew method - I.e duplicate vertices if there is per-face data specified in
    the brew parameters
###


{Matrix4, Vec3, Vec2} = require '../math/math'
{RGB,RGBA} = require '../colour/colour'
{Geometry, Vertex, Triangle, Quad} = require '../geometry/primitive'
{PXLWarning, PXLWarningOnce, PXLError} = require '../util/log'
{Contract} = require '../gl/contract'
{CacheVar} = require '../util/cache_var'

util = require "../util/util"

# ## GeometryBrewer
# A Mini Object attached to geometry in order for them
# to be drawn to the screen via webgl

GeometryBrewer = {}

# ## setDataBuffer
# set the data for a buffer

setDataBuffer = (buffer, data, type) ->
  gl = PXL.Context.gl
  gl.bindBuffer(gl.ARRAY_BUFFER, buffer)
  gl.bufferData(gl.ARRAY_BUFFER, data, type)
  gl.bindBuffer(gl.ARRAY_BUFFER, null)
  buffer

# ## createArrayBuffer
# create a buffer of data per vertex

createArrayBuffer = (data, type, size) ->
  gl = PXL.Context.gl
  buffer = gl.createBuffer()
  setDataBuffer buffer,data,type
  buffer.itemSize = size
  buffer.numItems = data.length / size
  buffer


# ## updateBuffer
# A call to bufferSubData essentially

bufferSubData = (buffer, data, offset) ->
  gl = PXL.Context.gl
  if not offset?
    offset = 0
  gl.bindBuffer(gl.ARRAY_BUFFER, buffer)
  gl.bufferSubData(gl.ARRAY_BUFFER, offset, data)
  gl.bindBuffer(gl.ARRAY_BUFFER, null)
  buffer

# ## createElementBuffer
# create a buffer of indices

createElementBuffer = (data, type, size) ->
  gl = PXL.Context.gl
  buffer = gl.createBuffer()
  gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, buffer)
  gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, data, type)
  buffer.itemSize = size
  buffer.numItems = data.length
  gl.bindBuffer(gl.ARRAY_BUFFER, null)
  buffer

# ## deleteBuffer
deleteBuffer = (buffer) ->
  gl = PXL.Context.gl
  gl.deleteBuffer(buffer)
  @


# ## _attribTypeCheckSet
# check and set an attribute pointer

_attribTypeCheckSet = (a, v) ->
  gl = PXL.Context.gl
  if a.pos == -1
    #PXLWarningOnce "Trying to set an attribute " + a.name + " that isnt used in the bound shader"
    return
      
  gl.bindBuffer(gl.ARRAY_BUFFER, v )

  if a.type == GL.LOW_INT or a.type == GL.MEDIUM_INT or a.type == GL.HIGH_INT or a.type == GL.INT
    gl.vertexAttribPointer(a.pos, 1, gl.INT, false, 0, 0)
  else if a.type == GL.LOW_FLOAT or a.type == GL.MEDIUM_FLOAT or a.type == GL.HIGH_FLOAT or a.type == GL.FLOAT
    gl.vertexAttribPointer(a.pos, 1, gl.FLOAT, false, 0, 0)
  else if a.type == GL.FLOAT_VEC2
    gl.vertexAttribPointer(a.pos, 2, gl.FLOAT, false, 0, 0)
  else if a.type == GL.FLOAT_VEC3
    gl.vertexAttribPointer(a.pos, 3, gl.FLOAT, false, 0, 0)
  else if a.type == GL.FLOAT_VEC4
    gl.vertexAttribPointer(a.pos, 4, gl.FLOAT, false, 0, 0)

  # TODO Attributes of matrices potentially for skeletal animation
  gl.enableVertexAttribArray(a.pos)
  @

# ## _uniformTypeCheckSet
# check and set a uniform

_uniformTypeCheckSet = (u,v) ->

  if u.pos == -1
    #PXLWarningOnce "Trying to set the uniform " + u.name + " that isnt used in the bound shader"
    return

  gl = PXL.Context.gl
  if u.size == 1
    if u.type == GL.LOW_FLOAT or u.type == GL.MEDIUM_FLOAT or u.type == GL.HIGH_FLOAT or u.type == GL.FLOAT
      gl.uniform1f(u.pos,v)
    else if u.type == GL.LOW_INT or u.type == GL.MEDIUM_INT or u.type == GL.HIGH_INT or u.type == GL.INT
      gl.uniform1i(u.pos,v)
    else if u.type == GL.FLOAT_VEC2
      gl.uniform2f(u.pos,v.x, v.y) # Vec2
    else if u.type == GL.FLOAT_VEC3
      if v.x?
        gl.uniform3f(u.pos, v.x, v.y, v.z) #Vec3
      else
        gl.uniform3f(u.pos, v.r, v.g, v.b) #Colour.RGB
    else if u.type == GL.FLOAT_VEC4
      if v.x?
        gl.uniform4f(u.pos,v.x, v.y, v.z, v.w) # Vec4
      else
        gl.uniform4f(u.pos,v.r, v.g, v.b, v.a) #Colour.RGBA
    else if u.type == GL.FLOAT_MAT4
      gl.uniformMatrix4fv(u.pos, false, v.a)  # Expecting a matrix here!
    else if u.type == GL.FLOAT_MAT3
      gl.uniformMatrix3fv(u.pos, false, v.a)
    else if u.type == GL.SAMPLER_2D
      # This is a bit tricksy as we are assuming we are passing an integer referring to the unit
      gl.uniform1i(u.pos, v)
    # TODO - Sampler cube

  else 
    
    if v instanceof Array
    
      if v[0] instanceof Object
        t = []
        if v[0].flatten?
          t = t.concat x.flatten() for x in v
          if u.type == GL.FLOAT_VEC2
            gl.uniform2fv u.pos, new Float32Array t # Vec2
          else if u.type == GL.FLOAT_VEC3
            gl.uniform3fv u.pos, new Float32Array t #Vec3
          else if u.type == GL.FLOAT_VEC4
            gl.uniform4fv u.pos, new Float32Array t
          else if u.type == GL.FLOAT_MAT3
            gl.uniformMatrix3fv u.pos, false, new Float32Array t
          else if u.type == GL.FLOAT_MAT4
            gl.uniformMatrix4fv u.pos, false, new Float32Array t
        else
          PXLWarningOnce("Cant set uniform " + u.name + " - no flatten() function")
      else

        if u.type == GL.LOW_FLOAT or u.type == GL.MEDIUM_FLOAT or u.type == GL.HIGH_FLOAT or u.type == GL.FLOAT
          gl.uniform1fv u.pos, new Float32Array v
        else if u.type == GL.LOW_INT or u.type == GL.MEDIUM_INT or u.type == GL.HIGH_INT or u.type == GL.INT
          gl.uniform1iv u.pos, new Int32Array v # integer
        else if u.type == GL.FLOAT_VEC2
          gl.uniform2fv u.pos, new Float32Array v # Vec2
        else if u.type == GL.FLOAT_VEC3
          gl.uniform3fv u.pos, new Float32Array v #Vec3
        else if u.type == GL.FLOAT_VEC4
          gl.uniform4fv u.pos, new Float32Array v # Vec4
        else if u.type == GL.FLOAT_MAT3
          gl.uniformMatrix3fv u.pos, false, new Float32Array v
        else if u.type == GL.FLOAT_MAT4
          gl.uniformMatrix4fv u.pos, false, new Float32Array v
    
    else if v instanceof Float32Array
      if u.type == GL.LOW_FLOAT or u.type == GL.MEDIUM_FLOAT or u.type == GL.HIGH_FLOAT or u.type == GL.FLOAT
        gl.uniform1fv u.pos, v
      else if u.type == GL.FLOAT_VEC2
        gl.uniform2fv u.pos, v # Vec2
      else if u.type == GL.FLOAT_VEC3
        gl.uniform3fv u.pos, v #Vec3
      else if u.type == GL.FLOAT_VEC4
        gl.uniform4fv u.pos, v # Vec4
      else if u.type == GL.FLOAT_MAT3
        gl.uniformMatrix3fv u.pos, false, v
      else if u.type == GL.FLOAT_MAT4
        gl.uniformMatrix4fv u.pos, false, v

    else if v instanceof Int32Array
      if u.type == GL.LOW_INT or u.type == GL.MEDIUM_INT or u.type == GL.HIGH_INT or u.type == GL.INT
        gl.uniform1iv u.pos, v # integer

  @

# ## _joinContracts
# Given an object or object hierarchy within a node, check them
# against the contract. Recursive call down all objects if they
# have a contract.
# TODO - is this function better off in the contract class?
# TODO - Possibly could be simplified 
_joinContracts = (obj, shader_contract) ->

  # Attempt to join the contracts
  if obj.contract?
    Contract.join(shader_contract, obj)
  

  # This is a bit crap but so far it's the best option to speed things up
  # We sort of need a reserved words on node / object really
  for prop of obj
    if prop in ["children", "faces", "indices", "vertices", "normals", "texcoords"]
      continue

    if obj[prop]? and typeof obj[prop] == "object"
     
      if obj[prop].contract?
        _joinContracts obj[prop], shader_contract

      else if obj[prop] instanceof Array
        for item in obj[prop]
          if typeof item == "object"
              _joinContracts item, shader_contract
  obj

# ## matchWithShader
# If this obj is drawable, match the uniforms
# Given the current context, we should have a shader with a @contract 
# if we do, attempt to match it. It is worth noting that one node on
# its own may not suffice for the entire shader contract and that 
# others may fill in the gaps further down.

# TODO - We need to do caching here as well I think

matchWithShader = (obj) ->

  if not PXL.Context.shader?
    PXLError("No Shader bound when calling matchWithShader")
    return obj
  if not PXL.Context.shader.contract?
    PXLError("No Shader contract when calling matchWithShader")
    return obj

  shader_contract = PXL.Context.shader.contract
  shader = PXL.Context.shader

  _joinContracts(obj, shader_contract)
      
  # Now we've joined contracts, lets check all the types
  # Hopefully they will be all matched at this point ;)
  # Match the uniforms first

  for u in shader_contract.uniforms
    if shader_contract.matches[u.name]?
      _uniformTypeCheckSet(u, shader_contract.matches[u.name])
  
  # Match the attributes
  for a in shader_contract.attributes
    if shader_contract.matches[a.name]?
      _attribTypeCheckSet(a, shader_contract.matches[a.name])

  obj
 


# ## GeometryBrewer.brew
# given some geometry, move that onto the graphics card. Called internally but also can be called by the user.
# params is a dictionary of parameters. Currently accepting: 
# <name>_buffer_access : GL.STATIC_DRAW, GL.DYNAMIC_DRAW etc


GeometryBrewer.brew = (params) ->

  if not @flat and (not @vertices? or @vertices.length <= 0)
    @brewed = false
    return @

  gl = PXL.Context.gl
  
  if not params?
    params = {}

  # We make the assumption that all vertices are the same in data
  # TODO - Eventually face colours and face normals

  # TODO - This repeats a lot so it should be tidied up a little I think
  # Also, combining buffers as well :O What then with our shader contracts?
  # ultimately, our shaders are still a little too decoupled, though with shader library
  # maybe we get around that?


  # Actually perform the brewing
  minorBrew = (obj, name,gattr,pattr,size) ->

    access = if params[pattr]? then params[pattr] else gl.STATIC_DRAW

    if obj.flat
      if not obj[name]?
        obj[name] = createArrayBuffer(obj[gattr], access, size)
      else
        if obj[gattr].length == obj[name].numItems
          setDataBuffer obj[name], obj[gattr], access
        else
          PXLWarningOnce "Attemping to update position buffer of different length"

    else
      new_verts = []
      new_verts = new_verts.concat v[gattr].flatten() for v in obj.vertices

      if not obj[name]? 
        # TODO - Always Float32Arrays?
        obj[name] = createArrayBuffer(new Float32Array(new_verts), access, size)
      else 
      # Assume if the same size, its the same order
        if obj.vertices.length == obj[name].numItems
          setDataBuffer obj[name], new Float32Array(new_verts), access
        else
          PXLWarningOnce "Attemping to update position buffer of different length"


  # Flat geometry is already in the arrays so we dont need to compress. We have the data
  if @flat

    # Look at the contract to decide what we compress
    for attrib of @contract.roles
      name = @contract.roles[attrib]
      key = name.replace("vertex","")
      key = key.replace("Buffer","")

      if @[ key ] instanceof Float32Array
        minorBrew @, name, key, key + "_buffer_access", @_flat_sizes[key]

  else
    # We look at everything that is attached to a vertex and is in
    # the contract with the right name. Must also have a DIM attached

    for key of @vertices[0]

      role_name = "vertex" + key + "Buffer"
      if @contract.hasRoleValue(role_name) and key != undefined
        vert = @vertices[0]
        datatype = vert[key]
        if not datatype.DIM?
          PXLError "No DIM provided for datatype sent to minorbrew"
        size = datatype.DIM
        minorBrew @, role_name, key, key + "_buffer_access", size
    
  # Indices
  access = if params.indices_buffer_access? then params.indices_buffer_access else gl.STATIC_DRAW

  if @indexed
    if @flat 
      @vertexIndexBuffer = createElementBuffer(@indices, access, 1)
    else
      if not @vertexIndexBuffer?
        @vertexIndexBuffer = createElementBuffer(new Uint16Array(@indices), access, 1)
      else
        if @indices.length == @vertexIndexBuffer.numItems
          setDataBuffer @vertexIndexBuffer, new Float32Array(@indices), access
        else
          PXLWarningOnce "Attemping to update indices buffer of different length"

  @brewed = true 
  @


# ## GeometryBrewer.rebrew
# For geometry that is already brewed, rebrew whichever has changed.
# The user must specify which buffers / vertex attribs to change :)
# params is a dictionary of parameters and is optional but at least
# one buffer must be set with its offset
# Currently accepting: 
# <name>_buffer : an integer representing the offset. 


GeometryBrewer.rebrew = (params) ->

  if not params?
    return @

  if @brewed == false
    return @

  gl = PXL.Context.gl

  for key of params
    if @flat
      name = "vertex" + key + "Buffer"
      if @[name]?
        bufferSubData @[name], @[key], params[key]
    else
      items = []
      items = items.concat v[key].flatten() for v in @vertices
      name = "vertex" + key + "Buffer"
      if @[name]?
        bufferData @[name], new Float32Array(items), params[key]

  @


# ## rebrew_typed
# For geometry that is already brewed, rebrew it as above but with the data already typed.
# For large geometries (anything above about 1000 verts) this method is much better
# This means the buffer will be out of sync with the data held on the geometry.
# params is a dictionary of parameters and is optional but at least
# one buffer must be set with its offset
# Currently accepting: 
# colour_buffer : another dictionary containing {offset: 0 , data : <typed_data> } 
# position_buffer : as above
# normal_buffer: as above
# texcoord_buffer : as above
# tangent_buffer : as above

rebrew_typed = (geometry, params) =>
  
  if not params?
    return @

  if @brewed == false
    return @

  gl = PXL.Context.gl

  # Colours
  if params.colour_buffer?
    if geometry.vertexcBuffer?
      bufferSubData(geometry.vertexcBuffer, params.colour_buffer.data, params.colour_buffer.offset)

  # Positions
  if params.position_buffer?
    if geometry.vertexpBuffer?
      bufferSubData(geometry.vertexpBuffer, params.position_buffer.data, params.position_buffer.offset)

  # normals
  if params.normal_buffer?
    if geometry.vertexnBuffer?
      bufferSubData(geometry.vertexnBuffer, params.normal_buffer.data, params.normal_buffer.offset)

  # UVs
  if params.texcoord_buffer?
    if geometry.vertextBuffer?
      bufferSubData(geometry.vertextBuffer, params.texcoord_buffer.data, params.texcoord_buffer.offset)

  # tangent
  if params.tangent_buffer?
    if geometry.vertexbBuffer?
      bufferSubData(geometry.vertexaBuffer, params.tangent_buffer.data, params.tangent_buffer.offset)

  @



# drawGL - bind the buffers and make the draw call
GeometryBrewer.drawGL = () -> 

  gl = PXL.Context.gl
  if @vertexIndexBuffer? and @indexed
    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, @vertexIndexBuffer);
    gl.drawElements(@layout, @vertexIndexBuffer.numItems, gl.UNSIGNED_SHORT,0);
  else
    gl.drawArrays(@layout, 0, @vertexpBuffer.numItems);
  @


# washup - remove any attachments to this node, and off the graphics card
# TODO - Needs testing I think

GeometryBrewer.washup = () ->
  
  for key of @
    if @[key] instanceof WebGLBuffer
      deleteBuffer @[key]


module.exports = 
  rebrew_typed : rebrew_typed
  GeometryBrewer : GeometryBrewer
  matchWithShader : matchWithShader
