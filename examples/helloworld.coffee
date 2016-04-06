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

  @n0 = new PXL.Node q
  @n1 = new PXL.Node 

  @c = new PXL.Camera.PerspCamera()



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
