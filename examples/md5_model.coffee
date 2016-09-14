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

class MD5Example

  init : () ->

    # Create a promise that resolves if the MD5 Model loads correctly
    @promise = new PXL.Util.Promise()

    @promise.then () =>
      g.matrix.rotate new PXL.Math.Vec3(1,0,0), -0.5 * PXL.Math.PI
      g.matrix.scale new PXL.Math.Vec3 0.1, 0.1, 0.1
      @top_node.add g
      # Create shaders once everything has loaded
      uber = new PXL.GL.UberShader 
      @top_node.add uber
      @g = g


    @top_node = new PXL.Node()

    # Create a new model, passing in the promise
    g = new PXL.Import.MD5Model "../models/hellknight/hellknight.md5mesh", @promise
    
    # Add a normal camera
    @c = new PXL.Camera.MousePerspCamera new PXL.Math.Vec3(0,0,25)
    @top_node.add @c

    @ambientlight = new PXL.Light.AmbientLight new PXL.Colour.RGB(0.001, 0.001, 0.01)
    @light = new PXL.Light.PointLight new PXL.Math.Vec3(10.0,5.0,-10.0), new PXL.Colour.RGB(0.8,0.1,0.1)
    @light2 = new PXL.Light.PointLight new PXL.Math.Vec3(-10.0,5.0,10.0), new PXL.Colour.RGB(0.0,0.9,0.9)

    cuboid = new PXL.Geometry.Cuboid new PXL.Math.Vec3 1,1,1
    cuboid_node = new PXL.Node cuboid, new PXL.Material.BasicColourMaterial(new PXL.Colour.RGB(1,0,0))

    @top_node.add @light
    @top_node.add @light2
    @top_node.add @ambientlight
    @top_node.add cuboid_node

    GL.enable(GL.CULL_FACE)
    GL.cullFace(GL.BACK)
    GL.enable(GL.DEPTH_TEST)


  draw : () ->

    GL.clearColor(0.95, 0.95, 0.95, 1.0)
    GL.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT)

    @top_node.draw()

    # Move the bone around if we've loaded the model
    if @g?
      bone = @g.skeleton.getBoneByName "luparm"
      q = PXL.Math.Quaternion.fromRotations 0,0.001,0
      bone.rotate q    

example = new MD5Example()

params = 
  canvas : 'webgl-canvas'
  context : example
  init : example.init
  draw : example.draw
  debug : true


cgl = new PXL.App params
