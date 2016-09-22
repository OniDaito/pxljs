
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
  var camera, flat_node, flat_plane, got_texture, hex_node, hex_plane, params, plane, plane_node;
  this.top_node = new PXL.Node();
  plane = new PXL.Geometry.Plane(8, 8);
  plane_node = new PXL.Node();
  plane_node.add(plane);
  flat_node = new PXL.Node();
  flat_plane = new PXL.Geometry.PlaneFlat(128, 128);
  flat_node.add(new PXL.Material.BasicColourMaterial(new PXL.Colour.RGB(1, 0, 0))).add(flat_plane);
  flat_node.matrix.translate(new PXL.Math.Vec3(0, -2.0, 0));
  hex_node = new PXL.Node();
  hex_plane = new PXL.Geometry.PlaneHexagonFlat(12, 12);
  hex_node.add(new PXL.Material.BasicColourMaterial(new PXL.Colour.RGB(0, 1, 0))).add(hex_plane);
  hex_node.matrix.translate(new PXL.Math.Vec3(0, 2.0, 0));
  this.top_node.add(hex_node);
  this.top_node.add(plane_node);
  this.top_node.add(flat_node);
  camera = new PXL.Camera.MousePerspCamera(new PXL.Math.Vec3(0, 2.0, 20.0));
  this.top_node.add(camera);
  got_texture = (function(_this) {
    return function(texture) {
      var material, uber;
      material = new PXL.Material.TextureMaterial(texture);
      _this.top_node.add(material);
      uber = new PXL.GL.UberShader(_this.top_node);
      return _this.top_node.add(uber);
    };
  })(this);
  params = {
    min: GL.NEAREST
  };
  PXL.GL.textureFromURL("/textures/chessboard.png", got_texture, void 0, params);
  return GL.enable(GL.DEPTH_TEST);
};

draw = function() {
  GL.clearColor(0.15, 0.15, 0.15, 1.0);
  GL.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT);
  return this.top_node.draw();
};

params = {
  canvas: 'webgl-canvas',
  context: this,
  init: init,
  draw: draw
};

cgl = new PXL.App(params);
