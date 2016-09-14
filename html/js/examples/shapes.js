
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

An example showing how we create basic shapes
 */
var ShapesExample, cgl, example, params;

ShapesExample = (function() {
  function ShapesExample() {}

  ShapesExample.prototype.init = function() {
    var angle, cube_node, cylinder_node, i, j, sphere_node, uber;
    this.top_node = new PXL.Node();
    this.c = new PXL.Camera.MousePerspCamera(new PXL.Math.Vec3(0, 0, 25));
    this.top_node.add(this.c);
    cube_node = new PXL.Node(new PXL.Geometry.Cuboid(new PXL.Math.Vec3(1, 2, 1)));
    cube_node.add(new PXL.Material.BasicColourMaterial(new PXL.Colour.RGB(1, 0, 0)));
    cube_node.matrix.translate(new PXL.Math.Vec3(1, 1, 3));
    cylinder_node = new PXL.Node(new PXL.Geometry.Cylinder(1, 5, 2, 4));
    cylinder_node.add(new PXL.Material.BasicColourMaterial(new PXL.Colour.RGB(0, 1, 0)));
    cylinder_node.matrix.translate(new PXL.Math.Vec3(-1, 0, -3));
    sphere_node = new PXL.Node(new PXL.Geometry.Sphere(1, 12, new PXL.Colour.RGBA(0, 0, 1, 1)));
    sphere_node.add(new PXL.Material.VertexColourMaterial());
    for (i = j = 0; j <= 27; i = ++j) {
      sphere_node.geometry.vertices[i].c = new PXL.Colour.RGBA(1, 0, 0, 1);
    }
    this.top_node.add(cube_node).add(cylinder_node).add(sphere_node);
    uber = new PXL.GL.UberShader(this.top_node);
    this.top_node.add(uber);
    GL.enable(GL.CULL_FACE);
    GL.cullFace(GL.BACK);
    GL.enable(GL.DEPTH_TEST);
    angle = PXL.Math.degToRad(1);
    this.rmatrix = new PXL.Math.Matrix4();
    this.rmatrix.rotate(new PXL.Math.Vec3(1, 0, 0), angle);
    this.rmatrix.rotate(new PXL.Math.Vec3(0, 1, 0), angle);
    return this.rmatrix.rotate(new PXL.Math.Vec3(0, 0, 1), angle);
  };

  ShapesExample.prototype.draw = function() {
    var j, len, n, ref, results;
    GL.clearColor(0.95, 0.95, 0.95, 1.0);
    GL.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT);
    this.top_node.draw();
    ref = this.top_node.children;
    results = [];
    for (j = 0, len = ref.length; j < len; j++) {
      n = ref[j];
      results.push(n.matrix.mult(this.rmatrix));
    }
    return results;
  };

  return ShapesExample;

})();

example = new ShapesExample();

params = {
  canvas: 'webgl-canvas',
  context: example,
  init: example.init,
  draw: example.draw,
  debug: true
};

cgl = new PXL.App(params);
