
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
  var ambientlight, magnolia, plane, spotlight, uniformMaterial, white;
  white = new PXL.Colour.RGBA.WHITE();
  magnolia = new PXL.Colour.RGBA.MAGNOLIA();
  plane = new PXL.Geometry.Plane(10, 10);
  this.n0 = new PXL.Node(plane);
  this.c = new PXL.Camera.MousePerspCamera();
  uniformMaterial = new PXL.Material.PhongMaterial(white, magnolia, white);
  this.n0.add(uniformMaterial);
  ambientlight = new PXL.Light.AmbientLight(new PXL.Colour.RGB(0.01, 0.01, 0.01));
  spotlight = new PXL.Light.SpotLight(new PXL.Math.Vec3(0, 2, 0), white, new PXL.Math.Vec3(0, -1, 0.1), PXL.Math.degToRad(10.0));
  this.n0.add(spotlight);
  this.topnode = new PXL.Node;
  this.topnode.add(this.n0);
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
