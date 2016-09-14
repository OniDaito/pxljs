
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
  var camera, t, v0, v1, v2, vertexMaterial, white;
  white = new PXL.Colour.RGBA.WHITE();
  v0 = new PXL.Geometry.Vertex({
    p: new PXL.Math.Vec3(-1, -1, 0),
    c: white
  });
  v1 = new PXL.Geometry.Vertex({
    p: new PXL.Math.Vec3(0, 1, 0),
    c: white
  });
  v2 = new PXL.Geometry.Vertex({
    p: new PXL.Math.Vec3(1, -1, 0),
    c: white
  });
  t = new PXL.Geometry.Triangle(v0, v1, v2);
  vertexMaterial = new PXL.Material.VertexColourMaterial();
  this.node = new PXL.Node(t);
  camera = new PXL.Camera.PerspCamera();
  this.node.add(camera);
  this.node.add(vertexMaterial);
  return this.node.add(new PXL.GL.UberShader(this.node));
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
