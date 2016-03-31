
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
  var q;
  q = new PXL.Geometry.Quad();
  this.n0 = new PXL.Node(q);
  PXL.GL.textureFromURL("/textures/wood.webp", (function(_this) {
    return function(texture) {
      _this.n0.add(new PXL.Material.TextureMaterial(texture));
      _this.topnode.add(_this.n0);
      return new PXL.GL.UberShader(_this.topnode);
    };
  })(this));
  this.c = new PXL.Camera.PerspCamera();
  this.topnode = new PXL.Node;
  return this.topnode.add(this.c);
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
