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
  @top_node = new PXL.Node()
  
  # A basic Z/X aligned plane
  plane = new PXL.Geometry.Plane(8,8)  
  plane_node = new PXL.Node()
  plane_node.add plane

  # A higher resolution flat plane
  flat_node = new PXL.Node()
  flat_plane = new PXL.Geometry.PlaneFlat(128,128)

  flat_node.add(new PXL.Material.BasicColourMaterial(new PXL.Colour.RGB(1,0,0))).add(flat_plane)
  flat_node.matrix.translate(new PXL.Math.Vec3(0,-2.0,0))

  # A Hexagon based plane
  hex_node = new PXL.Node()
  hex_plane = new PXL.Geometry.PlaneHexagonFlat(12,12)

  hex_node.add(new PXL.Material.BasicColourMaterial(new PXL.Colour.RGB(0,1,0))).add(hex_plane)
  hex_node.matrix.translate(new PXL.Math.Vec3(0,2.0,0))


  @top_node.add hex_node
  @top_node.add plane_node
  @top_node.add flat_node

  camera = new PXL.Camera.MousePerspCamera(new PXL.Math.Vec3(0,2.0,20.0))
  @top_node.add camera

  got_texture = (texture) =>
    material = new PXL.Material.TextureMaterial(texture)
    @top_node.add material
    uber = new PXL.GL.UberShader(@top_node)
    @top_node.add uber


  # Example of setting the parameters
  params = 
    min : GL.NEAREST

  PXL.GL.textureFromURL("/textures/chessboard.png", got_texture, undefined, params)  
  
  GL.enable GL.DEPTH_TEST

draw = () ->
  GL.clearColor(0.15, 0.15, 0.15, 1.0)
  GL.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT)
  @top_node.draw()

params = 
  canvas : 'webgl-canvas'
  context : @
  init : init
  draw : draw

cgl = new PXL.App params
