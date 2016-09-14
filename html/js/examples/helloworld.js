
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
  var q, t, uber, uniformMaterial, v0, v1, v2, vertexMaterial, white;
  white = new PXL.Colour.RGBA.WHITE();
  v0 = new PXL.Geometry.Vertex({
    p: new PXL.Math.Vec3(-1, -1, 0)
  });
  v1 = new PXL.Geometry.Vertex({
    p: new PXL.Math.Vec3(0, 1, 0)
  });
  v2 = new PXL.Geometry.Vertex({
    p: new PXL.Math.Vec3(1, -1, 0)
  });
  t = new PXL.Geometry.Triangle(v0, v1, v2);
  q = new PXL.Geometry.Quad();
  q.vertices[0].c = new PXL.Colour.RGBA(1.0, 0.0, 0.0, 1.0);
  q.vertices[1].c = new PXL.Colour.RGBA(0.0, 1.0, 0.0, 1.0);
  q.vertices[2].c = new PXL.Colour.RGBA(0.0, 0.0, 1.0, 1.0);
  this.n0 = new PXL.Node(t);
  this.n1 = new PXL.Node(q);
  this.n2 = new PXL.Node(t);
  this.n0.add(this.n2);
  this.n0.matrix.translate(new PXL.Math.Vec3(-1.1, 0, 0));
  this.n1.matrix.translate(new PXL.Math.Vec3(1.1, 0, 0));
  this.n2.matrix.scale(new PXL.Math.Vec3(0.5, 0.5, 0.5));
  this.n2.matrix.translate(new PXL.Math.Vec3(0.0, 1.5, 0.0));
  this.c = new PXL.Camera.PerspCamera();
  uniformMaterial = new PXL.Material.BasicColourMaterial(white);
  this.n0.add(uniformMaterial);
  vertexMaterial = new PXL.Material.VertexColourMaterial();
  this.n1.add(vertexMaterial);
  this.topnode = new PXL.Node;
  this.topnode.add(this.n0);
  this.topnode.add(this.n1);
  this.topnode.add(this.c);
  uber = new PXL.GL.UberShader(this.topnode);
  return this.topnode.add(uber);
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
