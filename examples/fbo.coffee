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

  @sphere_node = new PXL.Node new PXL.Geometry.Sphere(1,12,new PXL.Colour.RGBA(0,0,1,1)) 
  camera_mouse = new PXL.Camera.MousePerspCamera new PXL.Math.Vec3 0,1.5,12
  @sphere_node.add camera_mouse

  @sphere_node.add new PXL.Material.DepthMaterial()

  q = new PXL.Geometry.Quad() 
  c = new PXL.Camera.PerspCamera()
  @quad_node = new PXL.Node q
  @quad_node.add c

  @fbo = new PXL.GL.Fbo()
 
  @quad_node.add new PXL.Material.ViewDepthMaterial @fbo.texture
  
  uber = new PXL.GL.UberShader @sphere_node, @quad_node
  @sphere_node.add uber
  @quad_node.add uber


draw = () ->
  
  GL.clearColor(0.15, 0.15, 0.15, 1.0)
  GL.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT)

  @fbo.bind()
  GL.clearColor(0.0, 0.0, 0.0, 1.0)
  GL.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT)

  @sphere_node.draw()
  @fbo.unbind()

  @quad_node.draw()

params =
  canvas : 'webgl-canvas'
  context : @
  init : init
  debug : true
  draw : draw

cgl = new PXL.App params
