
/*
                       __  .__              ________ 
   ______ ____   _____/  |_|__| ____   ____/   __   \
  /  ___// __ \_/ ___\   __\  |/  _ \ /    \____    /
  \___ \\  ___/\  \___|  | |  (  <_> )   |  \ /    / 
 /____  >\___  >\___  >__| |__|\____/|___|  //____/  .co.uk
      \/     \/     \/                    \/         
                                              PXL
                                              Benjamin Blundell - ben@section9.co.uk
                                              http://www.section9.co.uk

This software is released under the MIT Licence. See LICENCE.txt for details
 */
var RayMarchExample, cgl, example, params;

RayMarchExample = (function() {
  function RayMarchExample() {}

  RayMarchExample.prototype.init = function() {
    var _tex_loaded, q, r;
    q = new PXL.Geometry.Quad();
    q.vertices[0].c = new PXL.Colour.RGBA(1.0, 0.0, 0.0, 1.0);
    q.vertices[1].c = new PXL.Colour.RGBA(0.0, 1.0, 0.0, 1.0);
    q.vertices[2].c = new PXL.Colour.RGBA(0.0, 0.0, 1.0, 1.0);
    r = new PXL.Util.Request('raymarch.glsl');
    r.get((function(_this) {
      return function(data) {
        return _this.shader = PXL.GL.shaderFromText(data);
      };
    })(this));
    this.n0 = new PXL.Node(q);
    this.c = new PXL.Camera.OrthoCamera(new PXL.Math.Vec3(0, 0, 0.1));
    this.n0.add(this.c);
    this.globaltime = 0;
    this.mp = new PXL.Math.Vec2(PXL.Context.width / 2, PXL.Context.height / 2);
    this.ml = false;
    this.mr = false;
    _tex_loaded = (function(_this) {
      return function(texture) {
        _this.t = texture;
        return _this.t.bind();
      };
    })(this);
    PXL.GL.textureFromURL("/textures/chessboard.png", _tex_loaded, void 0, {
      unit: 0,
      wrapt: GL.REPEAT,
      wraps: GL.REPEAT
    });
    PXL.Context.mouseMove.add(this.onMouseMove, this);
    PXL.Context.mouseDown.add(this.onMouseDown, this);
    return PXL.Context.mouseUp.add(this.onMouseUp, this);
  };

  RayMarchExample.prototype.onMouseMove = function(event) {
    this.mp.x = event.mouseX;
    return this.mp.y = event.mouseY;
  };

  RayMarchExample.prototype.onMouseUp = function(event) {
    if (event.buttonLeft) {
      this.ml = true;
    } else {
      this.ml = false;
    }
    if (event.buttonRight) {
      return this.mr = true;
    } else {
      return this.mr = false;
    }
  };

  RayMarchExample.prototype.onMouseDown = function(event) {
    if (event.buttonLeft) {
      this.ml = true;
    } else {
      this.ml = false;
    }
    if (event.buttonRight) {
      return this.mr = true;
    } else {
      return this.mr = false;
    }
  };

  RayMarchExample.prototype.draw = function(dt) {
    var dateObj, day, month, time, vm, year;
    this.globaltime += dt / 1000;
    GL.clearColor(0.15, 0.15, 0.15, 1.0);
    GL.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT);
    if (this.shader != null) {
      this.shader.bind();
      this.shader.setUniform3v("uResolution", new PXL.Math.Vec3(PXL.Context.width, PXL.Context.height, 0));
      this.shader.setUniform1f("uGlobalTime", this.globaltime);
      this.shader.setUniform1i("uChannel0", 0);
      vm = new PXL.Math.Vec4(this.mp.x, this.mp.y, 0, 0);
      if (this.ml) {
        vm.z = 1;
      }
      if (this.mr) {
        vm.w = 1;
      }
      this.shader.setUniform4v("uMouse", vm);
      dateObj = new Date();
      month = parseInt(dateObj.getUTCMonth());
      day = parseInt(dateObj.getUTCDate());
      year = parseInt(dateObj.getUTCFullYear());
      time = dateObj.getTime() / 1000;
      this.shader.setUniform4v("uDate", new PXL.Math.Vec4(year, month, day, time));
      this.n0.draw();
      return this.shader.unbind();
    }
  };

  return RayMarchExample;

})();

example = new RayMarchExample();

params = {
  canvas: 'webgl-canvas',
  context: example,
  init: example.init,
  draw: example.draw
};

cgl = new PXL.App(params);
