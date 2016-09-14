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

class OBJExample

  init : () ->

    @top_node = new PXL.Node()

    @promise = new PXL.Util.Promise()

    @promise.then () =>
      g.matrix.translate(new PXL.Math.Vec3(0,0,0))
      console.log "OBJ Node added"
      @top_node.add g
      uber = new PXL.GL.UberShader @top_node
      @top_node.add uber
      @obj_node = g
  
    g = new PXL.Import.OBJModel "../models/test.obj", @promise
  
    @c = new PXL.Camera.MousePerspCamera new PXL.Math.Vec3(0,0,25)
    @top_node.add @c

    @ambientlight = new PXL.Light.AmbientLight new PXL.Colour.RGB(0.1, 0.1, 0.1)
    @light = new PXL.Light.PointLight new PXL.Math.Vec3(0.0,0.0,2.0), new PXL.Colour.RGB(0.1,0.1,0.1)
    @light2 = new PXL.Light.PointLight new PXL.Math.Vec3(0.0,15.0,5.0), new PXL.Colour.RGB(0.4,0.1,0.1)

    @top_node.add @light
    @top_node.add @light2
    @top_node.add @ambientlight

    GL.enable(GL.CULL_FACE)
    GL.cullFace(GL.BACK)
    GL.enable(GL.DEPTH_TEST)

  draw : () ->

    GL.clearColor(0.95, 0.95, 0.95, 1.0)
    GL.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT)

    if @obj_node?
      @top_node.draw()


example = new OBJExample()

params = 
  canvas : 'webgl-canvas'
  context : example
  init : example.init
  draw : example.draw
  debug : true


cgl = new PXL.App params
