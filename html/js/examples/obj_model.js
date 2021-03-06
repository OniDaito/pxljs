
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
var OBJExample, cgl, example, params;

OBJExample = (function() {
  function OBJExample() {}

  OBJExample.prototype.init = function() {
    var g;
    this.top_node = new PXL.Node();
    this.promise = new PXL.Util.Promise();
    this.promise.then((function(_this) {
      return function() {
        var uber;
        g.matrix.translate(new PXL.Math.Vec3(0, 0, 0));
        console.log("OBJ Node added");
        _this.top_node.add(g);
        _this.obj_node = g;
        _this.c = new PXL.Camera.MousePerspCamera(new PXL.Math.Vec3(0, 0, 25));
        _this.top_node.add(_this.c);
        _this.ambientlight = new PXL.Light.AmbientLight(new PXL.Colour.RGB(0.1, 0.1, 0.1));
        _this.light = new PXL.Light.PointLight(new PXL.Math.Vec3(0.0, 0.0, 2.0), new PXL.Colour.RGB(0.1, 0.1, 0.1));
        _this.light2 = new PXL.Light.PointLight(new PXL.Math.Vec3(0.0, 15.0, 5.0), new PXL.Colour.RGB(0.4, 0.1, 0.1));
        _this.top_node.add(_this.light);
        _this.top_node.add(_this.light2);
        _this.top_node.add(_this.ambientlight);
        uber = new PXL.GL.UberShader(_this.top_node);
        return _this.top_node.add(uber);
      };
    })(this));
    g = new PXL.Import.OBJModel("../models/test.obj", this.promise);
    GL.enable(GL.CULL_FACE);
    GL.cullFace(GL.BACK);
    return GL.enable(GL.DEPTH_TEST);
  };

  OBJExample.prototype.draw = function() {
    GL.clearColor(0.95, 0.95, 0.95, 1.0);
    GL.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT);
    if (this.obj_node != null) {
      return this.top_node.draw();
    }
  };

  return OBJExample;

})();

example = new OBJExample();

params = {
  canvas: 'webgl-canvas',
  context: example,
  init: example.init,
  draw: example.draw,
  debug: true
};

cgl = new PXL.App(params);
