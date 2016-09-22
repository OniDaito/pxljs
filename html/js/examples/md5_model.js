
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
var MD5Example, cgl, example, params;

MD5Example = (function() {
  function MD5Example() {}

  MD5Example.prototype.init = function() {
    var cuboid, cuboid_node, g;
    this.top_node = new PXL.Node();
    this.c = new PXL.Camera.MousePerspCamera(new PXL.Math.Vec3(0, 0, 25));
    this.top_node.add(this.c);
    this.ambientlight = new PXL.Light.AmbientLight(new PXL.Colour.RGB(0.001, 0.001, 0.01));
    this.light = new PXL.Light.PointLight(new PXL.Math.Vec3(10.0, 5.0, -10.0), new PXL.Colour.RGB(0.8, 0.1, 0.1));
    this.light2 = new PXL.Light.PointLight(new PXL.Math.Vec3(-10.0, 5.0, 10.0), new PXL.Colour.RGB(0.0, 0.9, 0.9));
    cuboid = new PXL.Geometry.Cuboid(new PXL.Math.Vec3(1, 1, 1));
    cuboid_node = new PXL.Node(cuboid, new PXL.Material.BasicColourMaterial(new PXL.Colour.RGB(1, 0, 0)));
    this.top_node.add(this.light);
    this.top_node.add(this.light2);
    this.top_node.add(this.ambientlight);
    this.top_node.add(cuboid_node);
    this.promise = new PXL.Util.Promise();
    this.promise.then((function(_this) {
      return function() {
        var uber;
        g.matrix.rotate(new PXL.Math.Vec3(1, 0, 0), -0.5 * PXL.Math.PI);
        g.matrix.scale(new PXL.Math.Vec3(0.1, 0.1, 0.1));
        _this.top_node.add(g);
        uber = new PXL.GL.UberShader(_this.top_node);
        _this.top_node.add(uber);
        return _this.g = g;
      };
    })(this));
    GL.enable(GL.CULL_FACE);
    GL.cullFace(GL.BACK);
    GL.enable(GL.DEPTH_TEST);
    return g = new PXL.Import.MD5Model("../models/hellknight/hellknight.md5mesh", this.promise);
  };

  MD5Example.prototype.draw = function() {
    var bone, q;
    GL.clearColor(0.95, 0.95, 0.95, 1.0);
    GL.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT);
    this.top_node.draw();
    if (this.g != null) {
      bone = this.g.skeleton.getBoneByName("luparm");
      q = PXL.Math.Quaternion.fromRotations(0, 0.001, 0);
      return bone.rotate(q);
    }
  };

  return MD5Example;

})();

example = new MD5Example();

params = {
  canvas: 'webgl-canvas',
  context: example,
  init: example.init,
  draw: example.draw,
  debug: true
};

cgl = new PXL.App(params);
