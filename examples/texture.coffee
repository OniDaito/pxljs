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

  # Create our basic quad
  q = new PXL.Geometry.Quad()
  @n0 = new PXL.Node q

  # Fire a request for a texture
  PXL.GL.textureFromURL "/textures/wood.webp", (texture) =>

    # Create our texture from the data and add it to our material    
    @n0.add new PXL.Material.TextureMaterial texture

    # Our node is complete - add it to the topnode
    @topnode.add @n0
    @topnode.add new PXL.GL.UberShader(@topnode)

  @c = new PXL.Camera.PerspCamera()
  @topnode = new PXL.Node
  @topnode.add @c


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
