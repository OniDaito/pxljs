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


Primitive Objects - holds support for the various buffers we need


 - TODO
  * Should we use mixins or similar for adding texture co-ords and colours?
  * There is probably a much better methodology here I think
  * draw should be implicit when a primitive is created / added methinx - but what of order? Placement? Z Depth?

Three uses a dynamic flag. potential there.
Need to bind functions so that if vertices are updated, we change the buffers! Should be possible
Also, we are assuming floats here too! Normally thats the case but not always I suspect!
Also GL_TRIANGLES as well (but thats probably for the best)
Context is taken from the actual context set in the object but what if we wish to change context?
When applying materials, we may need to AUTOGEN stuff - thats not a bad idea actually

###

{RGBA,RGB} = require '../colour/colour'
{Matrix4,Vec2,Vec3,Vec4} = require '../math/math'
{Contract} = require '../gl/contract'
{GeometryBrewer} = require '../gl/webgl'
{PXLWarning, PXLError, PXLLog} = require '../util/log'

util = require '../util/util'

###Geometry###
# Represents actually geometry - a collection of vertices that can be drawn, with some
# organisation
# Geometry is either a set of vertices ready to be flattened into arrays to go onto the
# GPU or there is a set of existing Float32Arrays with the data
# The latter is called @flat
# Context must already be enabled as we are using gl constants (good idea?)
# @vertices - vertices - actual vertices if any. If this geometry is flat we use vertex components
#   - i.e @p for position, @t for texcoords etc
# @layout - gl constant to say how this should be treated (lines etc)

class Geometry
  constructor : () ->
    @vertices = []
    
    # By using a context here, we do end up needing a context at this point
    # we arent really decoupled with our geometry - tough choice really
    # TODO - Could just use the numbers? - I think we will :D

    @layout = GL.TRIANGLES if GL?
    @flat = false # A Hint that suggests the data is already held in flat, Float32Arrays
    @_flat_sizes = {} # Record the sizes if using a flat structure
    @faces = []
    @indexed = false
    @indices = []
    @contract = new Contract()

    # The default roles
    # TODO - Contract should probably be split into user and default with default being
    # static - Can probably do that in the contract class
    # atm we only check for the named variable 'contract' - perhaps there is a better way?
    @contract.roles.aVertexPosition   = "vertexpBuffer"
    @contract.roles.aVertexTexCoord   = "vertextBuffer"
    @contract.roles.aVertexNormal     = "vertexnBuffer"
    @contract.roles.aVertexColour     = "vertexcBuffer"
    @contract.roles.aVertexTangent    = "vertexaBuffer"
    @contract.roles.aVertexBarycentre = "vertexyBuffer"
    @contract.roles.aVertexSkinWeight = "vertexwBuffer"
    @contract.roles.aVertexBoneIndex  = "vertexiBuffer"

    util.extend(@, GeometryBrewer)
    @brewed = false

  _addToNode : (node) ->
    node.geometry = @  
    @

  flatten :() ->
    t = []
    for vertex in @vertices
      t.concat vertex.flatten()
    t

  setIndex : (idx, value) ->
    @indices[idx] = value
    @

  setVertex : (idx, vertex) ->
    @vertices[idx] = vertex
    @

  addVertex : (v) ->
    @vertices.push v
    @

  addIndex : (idx) ->
    @indices.push idx

  # getTrisIndexer - returns a function that allows us to iterate over the triangles
  # We look at the instanceof for the organisation of the triangles
  # TODO - Non indexed TRIANGLE_STRIPs need to be sorted

  getTrisIndexer : () ->
  
    flat_indexed_tris = (index) =>
      return [ new Vec3( @p[ @indices[index * 3] * 3 ], @p[ @indices[index * 3] * 3 + 1 ], @p[ @indices[index * 3] * 3 + 2]),
        new Vec3( @p[ @indices[index * 3 + 1] * 3], @p[ @indices[index * 3 + 1] * 3 + 1], @p[ @indices[index * 3 + 1] * 3 + 2]),
        new Vec3( @p[ @indices[index * 3 + 2] * 3], @p[ @indices[index * 3 + 2] * 3 + 1], @p[ @indices[index * 3 + 2] * 3 + 2])]
  

    flat_non_indexed_tris = (index) =>
      return [ new Vec3( @p[ index * 9], @p[ index * 9 + 1], @p[ index * 9 + 2]),
        new Vec3( @p[ index * 9 + 3], @p[ index * 9 + 4], @p[ index * 9 + 5]),
        new Vec3( @p[ index * 9 + 6], @p[ index * 9 + 7], @p[ index * 9 + 8])]

    pointy_indexed_tris = (index) =>
      return [@vertices[ @indices[index * 3]], @vertices[ @indices[index * 3 + 1]], @vertices[ @indices[index * 3 + 2]]]

    point_non_indexed_tris = (index) =>
      return [@vertices[ index * 3], @vertices[ index * 3 + 1], @vertices[ index * 3 + 2]]

    if @flat
      if @indexed
        return flat_indexed_tris
      else
        return flat_non_indexed_tris
    else
      if @indexed
        return pointy_indexed_tris
      else
        return point_non_indexed_tris

  # Return the number of triangles in this geometry
  getNumTris : () ->
    if @ instanceof PlaneFlat
      return @indices.length - 2

    # GL_TRIANGLES Based things
    if @flat
      if @indexed
        return @indices.length / 3
      else
        return @p.length / 3

    else
      if @indexed
        return @indices.length / 3
      else
        return @vertices.length / 3

###Vertex###
# Lowest class. We use this because we need to do things on a vertex basis when we brew
# We need position as a minimum. Optional Colour, Normal and texture and tangent
# vertices essentially copy by reference unless a Vec or similar is not copied. This is
# the general practice of PXL - inkeeping with javascript
# The defaults are
# @p - position
# @c - colour
# @n - normals
# @t - textures (u,v)
# @a - tangent
# @y - barycentre
# @w - skinweight
# @i - boneindex
# It is possible to pass in more arguments. Any object held on the vertex will be converted
# to a buffer of the same name + ""

class Vertex
  
  # You can pass in whatever named arguments you want. They will be attached to the 
  # Vertex object. Some of these have default names, such as p for position and 
  # c for colour. So pass in { 'p' :  Vec3(1,1,1) } for example
  constructor: (named_arguments) ->

    # Copy the bits over
    for key of named_arguments
      @[key] = named_arguments[key]

    # TODO - We should check the types being passed in, particularly if we are in debug mode

    if not @p?
      @p = new Vec3 0,0,0

  flatten: () ->
    t = []

    # Flatten all keys
    for key of @
      t.concat @[key].flatten()

    t



###Triangle###
# A triangle. This CAN be extended to be drawn on its own but doesnt have to be
# TODO - is a Triangle really geometry? It is kinda but since we have loads of triangles
# in things like a mesh shouldnt we really not do that? :S

class Triangle extends Geometry
  constructor: (p0,p1,p2,@n) ->
    super()
    # we dont have 3 vectors, create a unit triangle with -1 to 1 with anticlockwise winding

    if not p0? or not p1? or not p2?
      @vertices = [ 
        new Vertex
          p : new Vec3 -1,-1,0 
        new Vertex
          p : new Vec3 1,-1,0 
        new Vertex
          p : new Vec3 0,1,0
      ]
    else
      @vertices = [p0,p1,p2]

    @computeFaceNormal() if not @n?

  flatten: () ->
    t = []
    t = t.concat @vertices[0].flatten()
    t = t.concat @vertices[1].flatten()
    t = t.concat @vertices[2].flatten()
    t
  
  computeFaceNormal: ()->
    l0 = Vec3.sub(@vertices[1].p, @vertices[0].p)
    l1 = Vec3.sub(@vertices[2].p, @vertices[1].p)
    @n = l0.cross(l1)
    @n.normalize()
    
    @


###Quad###
# Our basic Quad, drawn as a tristrip. Assume planar triangles

class Quad extends Geometry

  constructor: (p0,p1,p2,p3,@n) ->
    super()
    # we dont have 4 vectors, create a 2 wide quad with -1 to 1 with anticlockwise winding
    if not p0? or not p1? or not p2? or not p3?
      p0 = new Vertex
        p : new Vec3 -1,1,0 
        c : new RGBA 1.0,1.0,1.0,1.0
        n : new Vec3 0,0,1
        t : new Vec2 0,1

      p1 = new Vertex 
        p : new Vec3 -1,-1,0
        c : new RGBA 1.0,1.0,1.0,1.0
        n : new Vec3 0,0,1
        t : new Vec2 0,0
      
      p2 = new Vertex
        p : new Vec3 1,1,0
        c : new RGBA 1.0,1.0,1.0,1.0
        n : new Vec3 0,0,1
        t : new Vec2 1,1
      
      p3 = new Vertex
        p : new Vec3 1,-1,0
        c : new RGBA 1.0,1.0,1.0,1.0
        n : new Vec3 0,0,1
        t : new Vec2 1,0

    @vertices = [p0,p1,p2,p3]
    gl = GL
    @layout = GL.TRIANGLE_STRIP if GL?

    @computeFaceNormal() if not @n?
  
  computeFaceNormal: ()->
    l0 = Vec3.sub(@vertices[1].p, @vertices[0].p)
    l1 = Vec3.sub(@vertices[2].p, @vertices[1].p)
    @n = l0.cross(l1)
    @n.normalize()
   
    @

  flatten: () ->
    t = []
    t = t.concat @vertices[0].flatten()
    t = t.concat @vertices[1].flatten()
    t = t.concat @vertices[2].flatten()
    t = t.concat @vertices[3].flatten()
    t




### VertexSoup ###
# A Place holder class for a collection of non indexed vertices, likely to be drawn out as lines
# or some arbitrary polygon
# vertex_list - the list of vertices to make this from

class VertexSoup extends Geometry 
  constructor: (vertex_list) ->
    super()
    gl = GL
    @layout = GL.POINTS if GL?
    @vertices = vertex_list



###TriangleMesh###
# A mesh made up of triangles that have the same kinds of vertices
# Can be created in several ways but the outcome is a set of indexed
# or non indexed buffers
# By adding triangles / quads we copy the vertex data semantically 
# but dont actually keep the underlying primitives save for the vertices
# We can infer the triangles back from this however should we wish

class TriangleMesh extends Geometry

  # TODO - allow indexing but also allowing passing in indices as well - speeds things 
  # up with the json model

  constructor : (indexed) ->
    super()
    @vertices = []
    @faces = []
    @indexed = indexed

    @layout = GL.TRIANGLES if GL?

  # Add a triangle to this mesh checking for any problems with vertex duplication
  addTriangle : (t) ->
    if @indexed
      for idx in [0..2]
        p = @_findV(t.vertices[idx]) 
        if p == -1
          @vertices.push t.vertices[idx]
          ti = @vertices.length
          ti -= 1
          t.vertices[idx]._idx = ti
          @indices.push ti

        else
          @indices.push(p)

    else
      @vertices.push v for v in t.v

    @faces.push(t)
    @




  # If we've added indicies by hand, we can create triangles from these
  # indices. Used in the MD5Model class
  addTriangleFromIndices : (indices) ->
    if @indexed
      points = []
      for idx in indices
        if idx > -1 and idx < @indices.length
          points.push @vertices[idx]
        else 
          PXLError "Attempting to create a triangle from indicies that dont exist"

      t = new Triangle @vertices[points[0]], @vertices[points[1]], @vertices[points[2]]
      @faces.push t 

    @



  # addQuad - Add a quad, breaking it down into its component parts
  addQuad : (q) ->

    if @indexed? == true     
      for idx in [0,1,3]
        p = @_findV(q.vertices[idx]) 
        if p == -1
          @vertices.push q.vertices[idx]
          ti = @vertices.length
          ti -= 1
          q.vertices[idx]._idx = ti
          @indices.push(ti)
        else
          @indices.push(p)

      for idx in [2,3,1]
        p = @_findV(q.vertices[idx]) 
        if p == -1
          @vertices.push q.vertices[idx]
          ti = @vertices.length
          ti -= 1
          q.vertices[idx]._idx = ti
          @indices.push ti
        else
          @indices.push(p)

    else
      @vertices.push q.vertices[i] for i in [0,1,3]
      @vertices.push q.vertices[i] for i in [2,3,1]

    @faces.push(new Triangle(q.vertices[0], q.vertices[1], q.vertices[3]))
    @faces.push(new Triangle(q.vertices[2], q.vertices[3], q.vertices[1]))
    
    @

  # _findV - Find the position in the array for this vertex
  # to speed this up we use a temporary _idx attribute if it exists
  _findV : (vf) ->
    return vf._idx if vf._idx?

    if @vertices.length > 0
      for idx in [0..(@vertices.length - 1)]
        if @vertices[idx] == vf
          return idx
    
    return -1
      
module.exports =
  Geometry : Geometry 
  Vertex: Vertex
  Triangle : Triangle
  Quad : Quad
  TriangleMesh : TriangleMesh 
  VertexSoup : VertexSoup