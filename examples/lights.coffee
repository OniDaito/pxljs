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
  magnolia = new PXL.Colour.RGBA.MAGNOLIA()

  plane = new PXL.Geometry.Plane 10,10
  @n0 = new PXL.Node plane

  @c = new PXL.Camera.MousePerspCamera()

  uniformMaterial = new PXL.Material.PhongMaterial white, magnolia, white, 2
  @n0.add uniformMaterial

  sphere = new PXL.Geometry.Sphere 0.2,10
  basicMaterial = new PXL.Material.BasicColourMaterial white
  @n1 = new PXL.Node sphere
  @n1.matrix.translate new PXL.Math.Vec3(0,2,0)
  @n1.add basicMaterial

  ambientlight = new PXL.Light.AmbientLight new PXL.Colour.RGB(0.001,0.001,0.001)

  spotlight = new PXL.Light.SpotLight new PXL.Math.Vec3(0,2,0), white, new PXL.Math.Vec3(0,-1,0), PXL.Math.degToRad(20.0)
  @n0.add spotlight

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
