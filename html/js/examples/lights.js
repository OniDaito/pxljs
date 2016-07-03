
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
  var ambientlight, basicMaterial, c, cp, cube_node, magnolia, plane, q, shadowed_node, sphere, uniformMaterial, white;
  white = new PXL.Colour.RGBA.WHITE();
  magnolia = new PXL.Colour.RGBA.MAGNOLIA();
  plane = new PXL.Geometry.Plane(10, 10);
  shadowed_node = new PXL.Node(plane);
  q = new PXL.Geometry.Quad();
  c = new PXL.Camera.MousePerspCamera();
  cp = new PXL.Camera.PerspCamera();
  uniformMaterial = new PXL.Material.PhongMaterial(white, magnolia, white, 2);
  shadowed_node.add(uniformMaterial);
  sphere = new PXL.Geometry.Sphere(0.2, 10);
  basicMaterial = new PXL.Material.BasicColourMaterial(white);
  this.light_node = new PXL.Node(sphere);
  this.light_node.matrix.translate(new PXL.Math.Vec3(0, 2, 0));
  this.light_node.add(basicMaterial);
  cube_node = new PXL.Node(new PXL.Geometry.Cuboid(new PXL.Math.Vec3(0.5, 0.5, 0.5)));
  cube_node.add(new PXL.Material.BasicColourMaterial(new PXL.Colour.RGB(1, 0, 0)));
  cube_node.matrix.translate(new PXL.Math.Vec3(0.25, 0.25, 0));
  shadowed_node.add(cube_node);
  ambientlight = new PXL.Light.AmbientLight(new PXL.Colour.RGB(0.001, 0.001, 0.001));
  this.spotlight = new PXL.Light.SpotLight(new PXL.Math.Vec3(0, 2, 0), white, new PXL.Math.Vec3(0, -1, 0), PXL.Math.degToRad(30.0), true);
  shadowed_node.add(this.spotlight);
  this.quad_node = new PXL.Node(q);
  this.quad_node.add(cp);
  this.quad_node.add(new PXL.Material.ViewDepthMaterial(this.spotlight.shadowmap_fbo.texture));
  this.quad_node.matrix.translate(new PXL.Math.Vec3(1, -1, 0));
  this.topnode = new PXL.Node;
  this.topnode.add(shadowed_node);
  this.topnode.add(this.light_node);
  this.topnode.add(c);
  new PXL.GL.UberShader(this.topnode);
  new PXL.GL.UberShader(this.quad_node);
  return this.step = 0;
};

draw = function(dt) {
  var newpos;
  GL.clearColor(0.15, 0.15, 0.15, 1.0);
  GL.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT);
  this.topnode.draw();
  this.quad_node.draw();
  this.step += 0.01;
  newpos = new PXL.Math.Vec3(Math.sin(this.step), 2.0 + Math.sin(this.step), Math.cos(this.step));
  this.spotlight.pos.copy(newpos);
  return this.light_node.matrix.translatePart(newpos);
};

params = {
  canvas: 'webgl-canvas',
  context: this,
  init: init,
  debug: true,
  draw: draw
};

cgl = new PXL.App(params);
