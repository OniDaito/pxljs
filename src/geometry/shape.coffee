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

###

{Node} = require '../core/node'
{RGB,RGBA} = require '../colour/colour'
{Vec2, Vec3, PI, degToRad} = require '../math/math'
{Vertex, Triangle, Quad, Geometry} = require './primitive'

# ## Cuboid
# A basic Cuboid with indices

class Cuboid extends Geometry
  # TODO - Add resolution here?
  # TODO - Add tangents here too?

  # **constructor**
  # - **dim** - a Vec3 - Default Vec3(1,1,1)
  # - **colour** - a Colour
  
  constructor: (dim, colour) ->
    super()

    @indexed = true

    if not dim?
      dim = new Vec3 1.0,1.0,1.0

    w = dim.x / 2
    h = dim.y / 2
    d = dim.z / 2

    # front
    @vertices.push new Vertex 
      p : new Vec3 -w,-h,d
      n : Vec3.normalize new Vec3 -w,-h,d
      t : new Vec2 0,0 
    
    @vertices.push new Vertex 
      p : new Vec3 w,-h,d  
      n : Vec3.normalize new Vec3 w,-h,d
      t : new Vec2 1,0 
    
    @vertices.push new Vertex 
      p : new Vec3 w,h,d
      n : Vec3.normalize new Vec3 w,h,d 
      t : new Vec2 1,1
    
    @vertices.push new Vertex 
      p : new Vec3 -w,h,d  
      n : Vec3.normalize new Vec3 -w,h,d
      t : new Vec2 0,1

    # back
    @vertices.push new Vertex
      p : new Vec3 -w,-h,-d
      n : Vec3.normalize new Vec3 -w,-h,-d
      t : new Vec2 1,1 
    
    @vertices.push new Vertex
      p : new Vec3 w,-h,-d
      n : Vec3.normalize new Vec3 w,-h,-d
      t : new Vec2 1,0
    
    @vertices.push new Vertex 
      p : new Vec3 w,h,-d
      n : Vec3.normalize new Vec3 w,h,-d
      t : new Vec2 0,0
    
    @vertices.push new Vertex
      p : new Vec3 -w,h,-d
      n : Vec3.normalize new Vec3 -w,h,-d
      t : new Vec2 0,1 

    if colour?
      for v in @vertices
        v.c = colour

    @indices = [0,1,2,0,2,3,6,5,4,6,4,7,4,0,3,4,3,7,1,5,2,5,6,2,3,2,6,3,6,7,4,5,1,4,1,0]

    for i in [0..@indices.length-1] by 3
      @faces.push new Triangle(@vertices[@indices[i]], @vertices[@indices[i+1]], @vertices[@indices[i+2]])



# ## Sphere

# http://local.wasp.uwa.edu.au/~pbourke/texture_colour/spheremap/  Paul Bourke's sphere code
# We should weigh an alternative that reduces the batch count by using GL_TRIANGLES instead
# TODO - Add Tangents?
# TODO - not convinced this generation is correct

class Sphere extends Geometry

  # **@constructor**
  # - **radius** - a Number - Default 1.0
  # - **segments** - a Number - Default 10
  # - **colour** - a Colour
  constructor: (radius, segments, colour) ->
    super()
    gl = PXL.Context.gl # Global / Current context
    @layout = gl.TRIANGLE_STRIP

    if radius?
      if radius < 0
        radius = 1.0
    else
      radius - 1.0

    if segments?
      if segments < 0
        segments = 10
    else
      segments = 10

    for j in [0..segments/2]
      theta1 = j * 2 * PI / segments - (PI / 2)
      theta2 = (j + 1) * 2 * PI / segments - (PI / 2)

      for i in [0..segments+1]
        e0 = new Vec3()
   
        theta3 = i * 2 * PI / segments
 
        e0.x = Math.cos(theta1) * Math.cos(theta3)
        e0.y = Math.sin(theta1)
        e0.z = Math.cos(theta1) * Math.sin(theta3)

        p0 = Vec3.multScalar(e0,radius)
        c0 = new RGBA(1.0,1.0,1.0,1.0)
        t0 = new Vec2( 0.999 - i / segments, 0.999 - 2 * j / segments)
        v = new Vertex 
          p : p0
          t : t0
          n : e0   

        @vertices.push v

        e1 = new Vec3()

        e1.x = Math.cos(theta2) * Math.cos(theta3)
        e1.y = Math.sin(theta2)
        e1.z = Math.cos(theta2) * Math.sin(theta3)

        p1 = Vec3.multScalar(e1,radius)

        t1 = new Vec2( 0.999 - i / segments, 0.999 - 2 * (j+1) / segments)
        v = new Vertex
          p : p1
          n : e1
          t : t1
     
        @vertices.push v

    for i in [2..@vertices.length-1] by 1
      if i % 2 == 0
        @faces.push new Triangle(@vertices[i], @vertices[i-1], @vertices[i-2])
      else
        @faces.push new Triangle(@vertices[i], @vertices[i-2], @vertices[i-1])
    
    if colour?
      for v in @vertices
        v.c = colour


# ## Cylinder
# A basic cylinder
class Cylinder extends Geometry

  # **@constructor** 
  # - **radius** - a Number - Default 0.5
  # - **resolution** - a Number - Default 10
  # - **height** - a Number - Default 1.0
  # - **colour** - a Colour
  constructor: (radius, resolution, segments, height, colour) ->
    super()
    @indices = []

    @indexed = true
 
    # TODO - This could be neater
    if radius? 
      if radius < 0
        radius = 0.5
    else
      radius = 0.5

    if resolution?
      if resolution < 0
        resolution = 10.0
    else
      resolution = 10.0

    if segments?
      if segments < 0
        segments = 10
    else
      segments = 10

    if height?
      if height < 0
        height = 1.0
    else
      height = 1.0

    hstep = height / segments
    height = height / 2.0

    # top
    @vertices.push new Vertex 
      p : new Vec3(0,height,0)
      n : new Vec3(0,1.0,0.0)
      t : new Vec2(0.5,0.0)
      a : new Vec2(0,0,0) # cx this - hairy coconut
    
    for i in [1..resolution]

      x = radius * Math.sin degToRad(360.0 / resolution * i)
      z = radius * Math.cos degToRad(360.0 / resolution * i)
      
      tangent = new Vec3(x,0,z)
      tangent.normalize()
      tangent.cross new Vec3(0,1,0)

      @vertices.push new Vertex 
        p : new Vec3(x,height,z)
        n : Vec3.normalize(new Vec3(x,1.0,z)) 
        t : new Vec2(i/resolution, 0.0) 
        a : tangent
    
    # top cap
    for i in [1..resolution]
      @indices.push 0
      @indices.push i
      if i == resolution
        @indices.push 1
      else
        @indices.push (i+1)

    for i in [1..segments]

      # next end
      for j in [1..resolution]

        x = radius * Math.sin degToRad(360.0 / resolution * j)
        z = radius * Math.cos degToRad(360.0 / resolution * j)

        tangent = new Vec3(x,0,z)
        tangent.normalize()
        tangent.cross new Vec3(0,-1,0)

        n0 = Vec3.normalize(new Vec3(x,0,z))
        if i == segments
          n0 = Vec3.normalize(new Vec3(x,-1,z))
        
        @vertices.push new Vertex 
          p : new Vec3(x, height - (hstep * i) ,z) 
          n : n0
          t : new Vec2(j/resolution, i/segments ) 
          a : tangent

      #sides1
      s = (i - 1) * resolution + 1
      e = s + resolution
  
      for j in [0..resolution-1]
        @indices.push (s + j)
        @indices.push (e + j)
        if j == (resolution-1)
          @indices.push (e)
        else
          @indices.push (e + j + 1)
      
      for j in [0..resolution-1]
        @indices.push (s+j)
        if j == (resolution-1)
          @indices.push (e)
          @indices.push (s)
        else
          @indices.push (e+j+1)
          @indices.push (s+j+1)

    # Very last point for bottom cap
    @vertices.push new Vertex 
      p : new Vec3(0,-height,0)
      n : new Vec3(0,-1.0,0.0)
      t : new Vec2(0.5,1.0)
      a : new Vec3(0,0,0)

     # bottom cap
    s = (segments * resolution) + 2
    e = s + resolution - 1
    for i in [s..e]
      @indices.push (s - 1)
      if i == e
        @indices.push s
      else
        @indices.push (i+1)

      @indices.push i

    for i in [0..@indices.length-1] by 3
      @faces.push new Triangle @vertices[@indices[i]], @vertices[@indices[i+1]], @vertices[@indices[i+2]]

    # Add colour - convert to RGBA here as that is what we expect in the shader
    # Potentially this is bad but attributes are what they are and this is cheaper
    if colour?
      if not colour.a?
        colour = new RGBA(colour.r,colour.g,colour.b,1.0)
      for v in @vertices
        v.c = colour

    @


module.exports = 
  Cuboid: Cuboid
  Sphere: Sphere
  Cylinder : Cylinder
  
 
