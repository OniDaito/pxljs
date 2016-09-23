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

{RGBA,RGB} = require '../colour/colour'
{Matrix4,Vec2,Vec3,Vec4} = require '../math/math'
{Geometry, Vertex, Quad} = require './primitive'


# ## Plane
# Basically, a varying resolution Quad made up of quads, -1 to 1, parallel to x/z plane
# Quads are added but the indices are triangles
# TODO - faces as quads? Perhaps not the best idea

class Plane extends Geometry 

  # **@constructor**
  # - **xres** - a Number
  # - **yres** - a Number
  constructor: (xres=1, zres=1) ->
    super()
    @v = []
    @faces = []
    @indexed = true
    @indices = []

    for i in [0..zres]
      for j in [0..xres]
        xp = -1.0 + (2.0 / (xres+1) * j)
        zp = -1.0 + (2.0 / (zres+1) * i)
        xt = 1.0 / xres * j
        zt = 1.0 / zres * i
        
        @vertices.push new Vertex
          p : new Vec3 xp,0,zp
          c : new RGBA 1.0,1.0,1.0,1.0
          n : new Vec3 0,1,0
          t : new Vec2 xt,zt

    # create indices as triangles - anti-clockwise winding
    for z in [0..zres-1]
      for x in [0..xres-1]
        row = (xres+1)*z
        row2 = (xres+1)*(z+1)

        @indices.push row+x
        @indices.push row2+x
        @indices.push row+x+1
        @indices.push row+x+1
        @indices.push row2+x
        @indices.push row2+x+1
        
        @faces.push new Quad @v[row2+x], @v[row2+x+1], @v[row+x+1], @v[row+x]  

# ## PlaneFlat
# Flat refers to the data size being fixed and the arrays already set
# Vertices are arranged as a triangle strip. Vertices are indexed so 
# as not to show cracks. We use degenerate triangles in order to create
# a proper plane.
# Designed for really large meshes

# TODO - greater than 256x256 causes issues
# TODO - Tangents? Options for normals etc?

class PlaneFlat extends Geometry 

  # **@constructor**
  # - **xres** - a Number - Optional - Integer - Default 2
  # - **zres** - a Number - Optional - Integer - Default 2
  constructor: (xres=2, zres=2) ->
    super()
    # TODO - Can we have options here?

    tt = xres * zres

    @p = new Float32Array(tt * 3)
    @t = new Float32Array(tt * 2)
    @n = new Float32Array(tt * 3)
    @c = new Float32Array(tt * 4)
    @indices = new Uint16Array(xres * (zres - 1) * 2)
    
    # Set the sizes so WebGL knows how to read this buffer
    # We do this for flat geometry only
    @_flat_sizes  = 
      p : 3
      t : 2
      n : 3
      c : 4 

    @indexed = true
    @flat = true

    @layout = GL.TRIANGLE_STRIP if GL?

    idv = 0
    idt = 0
    idc = 0
    idn = 0
    idx = 0

    # create rows and columns of vertices - left to right, bottom to top
    for i in [0..zres-1]

      for j in [0..xres-1]

        xp = -1.0 + (2.0 / (xres-1) * j)
        zp = -1.0 + (2.0 / (zres-1) * i)

        @p[idv++] = xp
        @p[idv++] = 0
        @p[idv++] = zp

        xt = 1.0 / (xres-1) * j
        zt = 1.0 / (zres-1) * i

        @t[idt++] = xt
        @t[idt++] = zt

        @c[idc++] = 1.0
        @c[idc++] = 1.0
        @c[idc++] = 1.0
        @c[idc++] = 1.0

        @n[idn++] = 0.0
        @n[idn++] = 1.0
        @n[idn++] = 0.0


    # Now add the indices - triangle strip

    for i in [0..zres-2]

      if i % 2 == 0

        for j in [0..xres-1]
          
          @indices[idx++] = xres * i + j
          @indices[idx++] = xres * (i+1) + j
    
      else
        for j in [xres-1..0]

          @indices[idx++] = xres * (i+1) + j
          @indices[idx++] = xres * i + j


  # **getTrisIndexer** - Overridden from the Geometry Class as its the only one so far that uses a flat tristrip
  # - returns a function with the following parameters
  # -- **index** - a Number - Integer
  # -- returns a List of Vec3 - Length 3 - [v0,v1,v2]
  getTrisIndexer : () ->

    flat_indexed_tristrip = (index) =>
      return [ new Vec3( @p[ @indices[index] * 3 ], @p[ @indices[index ] * 3 + 1 ], @p[ @indices[index] * 3 + 2]),
        new Vec3( @p[ @indices[index + 1] * 3], @p[ @indices[index + 1] * 3 + 1], @p[ @indices[index + 1] * 3 + 2]),
        new Vec3( @p[ @indices[index+ 2] * 3], @p[ @indices[index + 2] * 3 + 1], @p[ @indices[index + 2] * 3 + 2])]


    return flat_indexed_tristrip


# ## PlaneHexagonFlat
# Very similar to the plane flat, only this one is laid out with pretty
# triangles as oppose to strips, with a ragged edge, giving regular hexagons
# Flat refers to the data size being fixed and the arrays already set
# It is indexed as otherwise, we get cracks.
# It also include the barycentre for rendering wireframe
# TODO - Tangents? Options for normals etc?
# TODO - Certain resolutions are causing issues

class PlaneHexagonFlat extends Geometry

  # **@constructor**
  # - **xres** - a Number - Optional - Integer - Default 2
  # - **zres** - a Number - Optional - Integer - Default 2
  # - **indexed** - a Boolean - Optional - Default true
  constructor: (@xres=2, @zres=2, indexed=true) ->
    super()
    # TODO - Can we have options here?

    ep = Math.floor(@zres/2) + 1 

    tt = 3 * @xres * @zres
    
    @indexed = indexed 

    if @indexed
      tt = (ep * (@xres-1)) + ((@zres - ep + 1) * (@xres-2)) 

    @p = new Float32Array(tt * 3)
    @t = new Float32Array(tt * 2)
    @n = new Float32Array(tt * 3)
    @c = new Float32Array(tt * 4)
    @indices = new Uint16Array( 3 * @xres * @zres)
    @y = new Float32Array(tt * 3) 

    @flat = true

    @layout = GL.TRIANGLES if GL?

    @_flat_sizes  = 
      p : 3
      t : 2
      n : 3
      c : 4
      y : 3 

    idv = 0
    idt = 0
    idc = 0
    idn = 0
    idx = 0
    idy = 0
    bc = 0
    idu = 0
    sstep = [0,1]

    edge_width = 2.0 / Math.ceil(@xres/2)
    tex_width = 1.0 / Math.ceil(@xres/2)
   
    barycentres = [[1,0,0], [0,1,0], [0,0,1]]

    points = @p
    texcoords = @t
    colours = @c
    normals = @n
    baries = @y
    
    if not @indexed
      tt = (ep * (@xres-1)) + ((@zres - ep + 1) * (@xres-2)) 
      points = new Float32Array(tt * 3)
      texcoords = new Float32Array(tt * 2)
      colours = new Float32Array(tt * 4)
      normals = new Float32Array(tt * 3)
      baries = new Float32Array(tt * 3) 
    

    # create rows and columns of vertices - left to right, bottom to top
    for i in [0..@zres]

      offset = 0
      tex_offset = 0

      # This row is the full width
      row_width = @xres - 1

      # but this one isnt
      if i % 2 == 0
        row_width = @xres - 2
        offset = edge_width / 2
        tex_offset = tex_width / 2
      
      # Barycentre stuff
      bc = sstep[idu]

      for j in [0..row_width-1]

        xp = -1.0 + (j * edge_width) + offset
        zp = -1.0 + (2.0 / (@zres) * i)

        points[idv++] = xp
        points[idv++] = 0
        points[idv++] = zp

        xt = tex_width * j + tex_offset
        zt = 1.0 / @zres * i

        texcoords[idt++] = xt
        texcoords[idt++] = zt

        colours[idc++] = 1.0
        colours[idc++] = 1.0
        colours[idc++] = 1.0
        colours[idc++] = 1.0

        normals[idn++] = 0.0
        normals[idn++] = 1.0
        normals[idn++] = 0.0

        # Barycentre
        # TODO - export barycentre calculation in a similar manner to compute tangents
        baries[idy++] = barycentres[bc][0]
        baries[idy++] = barycentres[bc][1]
        baries[idy++] = barycentres[bc][2]

        bc++
        if bc > 2
          bc = 0

      idu++
      if idu > 1
        idu = 0
    
    # Now add the indices - triangles
    
    for z in [0..@zres-1]

      row0 = Math.floor(z/2) * (@xres-2 + @xres-1)
      row1 = row0 + @xres - 2

      te = Math.ceil(@xres/2)
      be = Math.floor(@xres/2)
  
      odds = false
      if z % 2 != 0
        odds = true
        row0 = row1
        row1 = row0 + @xres - 1
        # Swap top edge / bottom edge
        tt = te
        te = be
        be = tt
    
      # bottom edge
      for x in [0..be-1]

        if odds
          @indices[idx++] = row1 + x
        else
          @indices[idx++] = row1 + x + 1

        @indices[idx++] = row0 + x + 1
        @indices[idx++] = row0 + x

      # top edge
      for x in [0..te-1]
        @indices[idx++] = row1 + x
        @indices[idx++] = row1 + x + 1
      
        if odds
          @indices[idx++] = row0 + x + 1
        else
          @indices[idx++] = row0 + x
   
    
    idt = 0
    idc = 0
    idp = 0
    idn = 0 
    idy = 0

    if not @indexed
      for i in [0..@indices.length-1]
        idx = @indices[i]
        for j in [0..2]
          @p[ idp++ ] = points[idx * 3 + j]

        for j in [0..3]
          @c[ idc++ ] = colours[idx * 4 + j]

        for j in [0..1]
          @t[ idt++ ] = texcoords[idx * 2 + j]

        for j in [0..2]
          @n[ idn++ ] = normals[idx * 3 + j]
        
        for j in [0..2]
          @y[ idy++ ] = baries[idx * 3 + j]

      @indices = []

module.exports =
  Plane : Plane 
  PlaneFlat : PlaneFlat
  PlaneHexagonFlat : PlaneHexagonFlat
    
