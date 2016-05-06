
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
  var ambientlight, basicMaterial, cube_node, light_node, magnolia, plane, shadowed_node, sphere, spotlight, uniformMaterial, white;
  white = new PXL.Colour.RGBA.WHITE();
  magnolia = new PXL.Colour.RGBA.MAGNOLIA();
  plane = new PXL.Geometry.Plane(10, 10);
  shadowed_node = new PXL.Node(plane);
  this.c = new PXL.Camera.MousePerspCamera();
  uniformMaterial = new PXL.Material.PhongMaterial(white, magnolia, white, 2);
  shadowed_node.add(uniformMaterial);
  sphere = new PXL.Geometry.Sphere(0.2, 10);
  basicMaterial = new PXL.Material.BasicColourMaterial(white);
  light_node = new PXL.Node(sphere);
  light_node.matrix.translate(new PXL.Math.Vec3(0, 2, 0));
  light_node.add(basicMaterial);
  cube_node = new PXL.Node(new PXL.Geometry.Cuboid(new PXL.Math.Vec3(0.5, 0.5, 0.5)));
  cube_node.add(new PXL.Material.BasicColourMaterial(new PXL.Colour.RGB(1, 0, 0)));
  cube_node.matrix.translate(new PXL.Math.Vec3(0.25, 0.25, 0));
  shadowed_node.add(cube_node);
  ambientlight = new PXL.Light.AmbientLight(new PXL.Colour.RGB(0.001, 0.001, 0.001));
  spotlight = new PXL.Light.SpotLight(new PXL.Math.Vec3(0, 2, 0), white, new PXL.Math.Vec3(0, -1, 0), PXL.Math.degToRad(20.0), true);
  shadowed_node.add(spotlight);
  this.topnode = new PXL.Node;
  this.topnode.add(shadowed_node);
  this.topnode.add(light_node);
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
