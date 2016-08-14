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
  v0 = new PXLjs.Vertex(new PXLjs.Vec3(-1,-1,0), new PXLjs.Colour.RGBA.WHITE())
  v1 = new PXLjs.Vertex(new PXLjs.Vec3(0,1,0), new PXLjs.Colour.RGBA.WHITE())
  v2 = new PXLjs.Vertex(new PXLjs.Vec3(1,-1,0), new PXLjs.Colour.RGBA.WHITE())

  t = new PXLjs.Geometry.Triangle(v0,v1,v2)

  @node = new PXLjs.Node t 
  @camera = new PXLjs.Camera.PerspCamera()
  @node.add @camera

  new PXL.GL.UberShader @node

draw = () ->
  GL.clearColor(0.15, 0.15, 0.15, 1.0)
  GL.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT)
  @node.draw()

params = 
  canvas : 'webgl-canvas'
  context : @
  init : init
  draw : draw

cgl = new PXL.App params