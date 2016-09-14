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

  # Get a couple of colours
  white = new PXL.Colour.RGBA.WHITE()
  magnolia = new PXL.Colour.RGBA.MAGNOLIA()

  # Create some geometry
  plane = new PXL.Geometry.Plane 10,10
  shadowed_node = new PXL.Node plane
  q = new PXL.Geometry.Quad() 
 
  # Cameras we need
  c = new PXL.Camera.MousePerspCamera()
  cp = new PXL.Camera.PerspCamera()

  # Materials and lights for the main scene
  uniformMaterial = new PXL.Material.PhongMaterial white, magnolia, white, 2
  shadowed_node.add uniformMaterial

  sphere = new PXL.Geometry.Sphere 0.2,10
  basicMaterial = new PXL.Material.BasicColourMaterial white
  @light_node = new PXL.Node sphere
  @light_node.matrix.translate new PXL.Math.Vec3(0,2,0)
  @light_node.add basicMaterial

  cube_node = new PXL.Node new PXL.Geometry.Cuboid(new PXL.Math.Vec3(0.5,0.5,0.5))
  cube_node.add new PXL.Material.BasicColourMaterial new PXL.Colour.RGB(1,0,0)
  cube_node.matrix.translate new PXL.Math.Vec3(0.25,0.25,0)

  shadowed_node.add cube_node

  ambientlight = new PXL.Light.AmbientLight new PXL.Colour.RGB(0.001,0.001,0.001)

  @spotlight = new PXL.Light.SpotLight new PXL.Math.Vec3(0,2,0), white, new PXL.Math.Vec3(0,-1,0), PXL.Math.degToRad(30.0), true
  shadowed_node.add @spotlight

  # our quad node for showing the lights view
  @quad_node = new PXL.Node q
  @quad_node.add cp

  @quad_node.add new PXL.Material.ViewDepthMaterial @spotlight.shadowmap_fbo.texture
  @quad_node.matrix.translate(new PXL.Math.Vec3(1,-1,0))

  # Now add the nodes and cameras for the main objects
  @topnode = new PXL.Node
  @topnode.add shadowed_node
  @topnode.add @light_node
  @topnode.add c

  uber0 = new PXL.GL.UberShader @topnode
  uber1 = new PXL.GL.UberShader @quad_node
  @topnode.add uber0
  @quad_node.add uber1

  @step = 0

draw = (dt) ->
  
  GL.clearColor(0.15, 0.15, 0.15, 1.0)
  GL.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT)

  # Draw out nodes
  @topnode.draw()
  @quad_node.draw()

  # Move the light around
  @step += 0.01

  newpos = new PXL.Math.Vec3(Math.sin(@step),2.0 + Math.sin(@step),Math.cos(@step))
  
  @spotlight.pos.copy newpos

  @light_node.matrix.translatePart newpos

params =
  canvas : 'webgl-canvas'
  context : @
  init : init
  debug : true
  draw : draw


cgl = new PXL.App params
