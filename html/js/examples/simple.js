
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
  var t, v0, v1, v2;
  v0 = new PXLjs.Vertex(new PXLjs.Vec3(-1, -1, 0), new PXLjs.Colour.RGBA.WHITE());
  v1 = new PXLjs.Vertex(new PXLjs.Vec3(0, 1, 0), new PXLjs.Colour.RGBA.WHITE());
  v2 = new PXLjs.Vertex(new PXLjs.Vec3(1, -1, 0), new PXLjs.Colour.RGBA.WHITE());
  t = new PXLjs.Geometry.Triangle(v0, v1, v2);
  this.node = new PXLjs.Node(t);
  this.camera = new PXLjs.Camera.PerspCamera();
  this.node.add(this.camera);
  return new PXL.GL.UberShader(this.node);
};

draw = function() {
  GL.clearColor(0.15, 0.15, 0.15, 1.0);
  GL.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT);
  return this.node.draw();
};

params = {
  canvas: 'webgl-canvas',
  context: this,
  init: init,
  draw: draw
};

cgl = new PXL.App(params);
