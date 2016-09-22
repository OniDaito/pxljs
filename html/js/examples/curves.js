
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
  var colour_spline, i, j, k, l, ny, p0, p1, p2, p3, p4, p5, p6, p7, patch_geometry, patch_points, polygon, polygon_shape, ref, res, spline, spline_verts, uber, v0, v1, v2, v3, v4, v5, v6, v7, vertexMaterial, white, xi, yi;
  p0 = new PXL.Math.Vec3(50, 350, 0);
  p1 = new PXL.Math.Vec3(100, 300, 0);
  p2 = new PXL.Math.Vec3(200, 300, 0);
  p3 = new PXL.Math.Vec3(200, 500, 0);
  p4 = new PXL.Math.Vec3(400, 480, 0);
  p5 = new PXL.Math.Vec3(350, 320, 0);
  p6 = new PXL.Math.Vec3(500, 100, 0);
  p7 = new PXL.Math.Vec3(200, 50, 0);
  polygon = [p0, p1, p2, p3, p4, p5, p6, p7];
  white = new PXL.Colour.RGBA.WHITE();
  v0 = new PXL.Geometry.Vertex({
    p: p0,
    c: white
  });
  v1 = new PXL.Geometry.Vertex({
    p: p1,
    c: white
  });
  v2 = new PXL.Geometry.Vertex({
    p: p2,
    c: white
  });
  v3 = new PXL.Geometry.Vertex({
    p: p3,
    c: white
  });
  v4 = new PXL.Geometry.Vertex({
    p: p4,
    c: white
  });
  v5 = new PXL.Geometry.Vertex({
    p: p5,
    c: white
  });
  v6 = new PXL.Geometry.Vertex({
    p: p6,
    c: white
  });
  v7 = new PXL.Geometry.Vertex({
    p: p7,
    c: white
  });
  polygon_shape = new PXL.Geometry.VertexSoup([v0, v1, v2, v3, v4, v5, v6, v7]);
  polygon_shape.layout = GL.LINE_LOOP;
  colour_spline = new PXL.Colour.RGBA(0.0, 1.0, 1.0, 0.8);
  spline = new PXL.Math.CatmullRomSpline(polygon);
  spline_verts = [];
  for (i = j = 1; j <= 500; i = ++j) {
    spline_verts.push(new PXL.Geometry.Vertex({
      p: spline.pointOnCurve(i / 500.0),
      c: colour_spline
    }));
  }
  this.spline_shape = new PXL.Geometry.VertexSoup(spline_verts);
  this.spline_shape.layout = GL.LINE_STRIP;
  patch_points = [];
  for (i = k = 0; k <= 15; i = ++k) {
    patch_points.push(new PXL.Math.Vec3((i % 4) - 1.5, 0.0, Math.floor(i / 4) - 1.5));
  }
  patch_points[5].y = 1.0;
  patch_points[6].y = 1.0;
  patch_points[9].y = 1.0;
  patch_points[10].y = 1.0;
  this.catmull_patch = new PXL.Math.CatmullPatch(patch_points);
  res = 100;
  this.persp_node = new PXL.Node;
  patch_geometry = new PXL.Geometry.PlaneFlat(res, res);
  for (i = l = 0, ref = patch_geometry.p.length - 1; 0 <= ref ? l <= ref : l >= ref; i = 0 <= ref ? ++l : --l) {
    xi = (i % res) / res;
    yi = Math.floor(i / res) / res;
    ny = this.catmull_patch.sample(new PXL.Math.Vec2(xi, yi));
    patch_geometry.p[i * 3] = ny.x;
    patch_geometry.p[i * 3 + 1] = ny.y;
    patch_geometry.p[i * 3 + 2] = ny.z;
  }
  patch_geometry.layout = GL.LINE_STRIP;
  this.persp_node.add(patch_geometry);
  vertexMaterial = new PXL.Material.VertexColourMaterial();
  this.persp_node.add(vertexMaterial);
  this.ortho_node = new PXL.Node;
  this.ortho_node.add(vertexMaterial);
  this.polygon_node = new PXL.Node;
  this.polygon_node_lines = new PXL.Node(polygon_shape);
  this.polygon_node.add(polygon_node_lines);
  this.spline_node = new PXL.Node(this.spline_shape);
  this.ortho_node.add(this.polygon_node);
  this.ortho_node.add(this.spline_node);
  this.ortho_camera = new PXL.Camera.OrthoCamera(new PXL.Math.Vec3(0, 0, 0.2), new PXL.Math.Vec3(0, 0, 0));
  this.ortho_node.add(this.ortho_camera);
  this.persp_camera = new PXL.Camera.MousePerspCamera(new PXL.Math.Vec3(0, 1, 6), new PXL.Math.Vec3(0, 0, 0));
  this.persp_node.add(this.persp_camera);
  uber = new PXL.GL.UberShader(this.persp_node, this.ortho_node);
  this.persp_node.add(uber);
  this.ortho_node.add(uber);
  GL.enable(GL.DEPTH_TEST);
  return GL.blendFunc(GL.SRC_ALPHA, GL.ONE);
};

draw = function() {
  GL.clearColor(0.15, 0.15, 0.15, 1.0);
  GL.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT);
  GL.lineWidth(1.0);
  this.ortho_node.draw();
  return this.persp_node.draw();
};

params = {
  canvas: 'webgl-canvas',
  context: this,
  init: init,
  draw: draw
};

cgl = new PXL.App(params);
