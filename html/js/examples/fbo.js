
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
  var c, camera_mouse, q, uber;
  this.sphere_node = new PXL.Node(new PXL.Geometry.Sphere(1, 12, new PXL.Colour.RGBA(0, 0, 1, 1)));
  camera_mouse = new PXL.Camera.MousePerspCamera(new PXL.Math.Vec3(0, 1.5, 12));
  this.sphere_node.add(camera_mouse);
  this.sphere_node.add(new PXL.Material.DepthMaterial());
  q = new PXL.Geometry.Quad();
  c = new PXL.Camera.PerspCamera();
  this.quad_node = new PXL.Node(q);
  this.quad_node.add(c);
  this.fbo = new PXL.GL.Fbo();
  this.quad_node.add(new PXL.Material.ViewDepthMaterial(this.fbo.texture));
  uber = new PXL.GL.UberShader(this.sphere_node, this.quad_node);
  this.sphere_node.add(uber);
  return this.quad_node.add(uber);
};

draw = function() {
  GL.clearColor(0.15, 0.15, 0.15, 1.0);
  GL.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT);
  this.fbo.bind();
  GL.clearColor(0.0, 0.0, 0.0, 1.0);
  GL.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT);
  this.sphere_node.draw();
  this.fbo.unbind();
  return this.quad_node.draw();
};

params = {
  canvas: 'webgl-canvas',
  context: this,
  init: init,
  debug: true,
  draw: draw
};

cgl = new PXL.App(params);
