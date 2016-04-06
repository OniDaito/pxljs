
/* ABOUT
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
 */
var cgl, draw, init, params;

init = function() {
  this.n0 = new PXL.Node(q);
  this.n1 = new PXL.Node;
  this.c = new PXL.Camera.PerspCamera();
  this.topnode = new PXL.Node;
  this.topnode.add(this.n0);
  this.topnode.add(this.n1);
  this.topnode.add(this.c);
  return new PXL.GL.UberShader(this.topnode);
};

draw = function() {
  GL.clearColor(0.15, 0.15, 0.15, 1.0);
  GL.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT);
  return this.topnode.draw();
};

params = {
  canvas: 'webgl-canvas',
  context: this,
  init: init,
  debug: true,
  draw: draw
};

cgl = new PXL.App(params);
