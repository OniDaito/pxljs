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


init = () ->

  white = new PXL.Colour.RGBA.WHITE()

  v0 = new PXL.Geometry.Vertex 
    p : new PXL.Math.Vec3(-1,-1,0)
  
  v1 = new PXL.Geometry.Vertex
    p : new PXL.Math.Vec3( 0, 1,0)

  v2 = new PXL.Geometry.Vertex 
    p : new PXL.Math.Vec3( 1,-1,0)

  t = new PXL.Geometry.Triangle v0,v1,v2

  q = new PXL.Geometry.Quad()

  q.vertices[0].c = new PXL.Colour.RGBA 1.0, 0.0, 0.0, 1.0
  q.vertices[1].c = new PXL.Colour.RGBA 0.0, 1.0, 0.0, 1.0
  q.vertices[2].c = new PXL.Colour.RGBA 0.0, 0.0, 1.0, 1.0

  @n0 = new PXL.Node t
  @n1 = new PXL.Node q
  @n2 = new PXL.Node t

  @n0.add @n2

  @n0.matrix.translate new PXL.Math.Vec3(-1.1,0,0)
  @n1.matrix.translate new PXL.Math.Vec3(1.1,0,0)

  @n2.matrix.scale new PXL.Math.Vec3(0.5,0.5,0.5)
  @n2.matrix.translate new PXL.Math.Vec3(0.0,1.5,0.0)

  @c = new PXL.Camera.PerspCamera()

  uniformMaterial = new PXL.Material.BasicColourMaterial white
  @n0.add uniformMaterial

  vertexMaterial = new PXL.Material.VertexColourMaterial()
  @n1.add vertexMaterial

  @topnode = new PXL.Node
  @topnode.add @n0
  @topnode.add @n1
  @topnode.add @c

  new PXL.GL.UberShader @topnode

draw = () ->
  
  GL.clearColor(0.15, 0.15, 0.15, 1.0)
  GL.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT)

  @topnode.draw()


params = 
  canvas : 'webgl-canvas'
  context : @
  init : init
  debug : true
  draw : draw

cgl = new PXL.App params
