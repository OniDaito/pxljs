
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
var Logo, cgl, example, params;

Logo = (function() {
  function Logo() {}

  Logo.prototype.reset_cubes = function() {
    var cube, j, len, ref, results;
    ref = this.cube_nodes;
    results = [];
    for (j = 0, len = ref.length; j < len; j++) {
      cube = ref[j];
      results.push(cube.matrix.identity());
    }
    return results;
  };

  Logo.prototype.arrange_cubes = function() {
    this.cube_nodes[0].matrix.translate(new PXL.Math.Vec3(-4.0, 3.0, 0.0));
    this.cube_nodes[1].matrix.translate(new PXL.Math.Vec3(-4.0, 2.0, 0.0));
    this.cube_nodes[2].matrix.translate(new PXL.Math.Vec3(-4.0, 1.0, 0.0));
    this.cube_nodes[3].matrix.translate(new PXL.Math.Vec3(-4.0, 0.0, 0.0));
    this.cube_nodes[4].matrix.translate(new PXL.Math.Vec3(-4.0, -1.0, 0.0));
    this.cube_nodes[5].matrix.translate(new PXL.Math.Vec3(-4.0, -2.0, 0.0));
    this.cube_nodes[6].matrix.translate(new PXL.Math.Vec3(-3.0, 3.0, 0.0));
    this.cube_nodes[7].matrix.translate(new PXL.Math.Vec3(-2.0, 3.0, 0.0));
    this.cube_nodes[8].matrix.translate(new PXL.Math.Vec3(-2.0, 2.0, 0.0));
    this.cube_nodes[9].matrix.translate(new PXL.Math.Vec3(-3.0, 1.0, 0.0));
    this.cube_nodes[10].matrix.translate(new PXL.Math.Vec3(-2.0, 1.0, 0.0));
    this.cube_nodes[11].matrix.translate(new PXL.Math.Vec3(-2.0, 0.0, 0.0));
    this.cube_nodes[12].matrix.translate(new PXL.Math.Vec3(0, 0, 0));
    this.cube_nodes[13].matrix.translate(new PXL.Math.Vec3(-1.0, -1.0, 0.0));
    this.cube_nodes[14].matrix.translate(new PXL.Math.Vec3(-2.0, -2.0, 0.0));
    this.cube_nodes[15].matrix.translate(new PXL.Math.Vec3(0.0, -2.0, 0.0));
    this.cube_nodes[16].matrix.translate(new PXL.Math.Vec3(1.0, 3.0, 0.0));
    this.cube_nodes[17].matrix.translate(new PXL.Math.Vec3(1.0, 2.0, 0.0));
    this.cube_nodes[18].matrix.translate(new PXL.Math.Vec3(1.0, 1.0, 0.0));
    this.cube_nodes[19].matrix.translate(new PXL.Math.Vec3(1.0, 0.0, 0.0));
    this.cube_nodes[20].matrix.translate(new PXL.Math.Vec3(1.0, -1.0, 0.0));
    this.cube_nodes[21].matrix.translate(new PXL.Math.Vec3(1.0, -2.0, 0.0));
    return this.cube_nodes[22].matrix.translate(new PXL.Math.Vec3(2.0, -2.0, 0.0));
  };

  Logo.prototype.rotate_cubes = function(dt) {
    var cube, dd, j, k, len, len1, ref, ref1, rot, stopped;
    dd = 0;
    stopped = true;
    ref = this.cube_nodes;
    for (j = 0, len = ref.length; j < len; j++) {
      cube = ref[j];
      rot = 1.0 + Math.sin(dd);
      if (cube._rot < 360) {
        cube._rot += rot;
        cube.matrix.rotate(new PXL.Math.Vec3(0, 1, 0), PXL.Math.degToRad(cube._rot));
        stopped = false;
      }
      dd += 0.1;
    }
    this.time += dt;
    if (!stopped) {
      this.pause_time = this.time;
    }
    if (stopped) {
      if (this.time - this.pause_time > 5000) {
        ref1 = this.cube_nodes;
        for (k = 0, len1 = ref1.length; k < len1; k++) {
          cube = ref1[k];
          cube._rot = 0;
        }
        this.time = 0;
        return this.pause_time = 0;
      }
    }
  };

  Logo.prototype.init = function() {
    var cc, cube_geometry, hot_pink, i, j, spec, uber;
    this.top_node = new PXL.Node();
    this.camera = new PXL.Camera.PerspCamera(new PXL.Math.Vec3(-6.62, -2.15, 7.29), new PXL.Math.Vec3(-1.17, 0.59, -0.64), new PXL.Math.Vec3(-0.16, 0.96, 0.23));
    this.top_node.add(this.camera);
    cube_geometry = new PXL.Geometry.CuboidDup(new PXL.Math.Vec3(1, 1, 1));
    hot_pink = new PXL.Colour.RGB(1.0, 0.41, 0.7);
    spec = new PXL.Colour.RGB(0.0, 0.0, 0.0);
    this.top_node.add(new PXL.Material.PhongMaterial(hot_pink, hot_pink, spec));
    this.cube_nodes = [];
    for (i = j = 0; j <= 22; i = ++j) {
      cc = new PXL.Node(cube_geometry);
      cc._rot = 0;
      this.cube_nodes.push(cc);
      this.top_node.add(cc);
    }
    this.ambientlight = new PXL.Light.AmbientLight(new PXL.Colour.RGB(0.1, 0.1, 0.1));
    this.light = new PXL.Light.PointLight(new PXL.Math.Vec3(0.0, 2.0, 6.0), new PXL.Colour.RGB(0.2, 0.2, 0.2));
    this.light2 = new PXL.Light.PointLight(new PXL.Math.Vec3(0.0, 15.0, 5.0), new PXL.Colour.RGB(0.2, 0.2, 0.2));
    this.top_node.add(this.light);
    this.top_node.add(this.light2);
    this.top_node.add(this.ambientlight);
    uber = new PXL.GL.UberShader(this.top_node);
    this.top_node.add(uber);
    this.time = 0;
    this.pause_time = 0;
    GL.enable(GL.CULL_FACE);
    GL.cullFace(GL.BACK);
    return GL.enable(GL.DEPTH_TEST);
  };

  Logo.prototype.draw = function(dt) {
    this.reset_cubes();
    this.arrange_cubes();
    this.rotate_cubes(dt);
    GL.clearColor(1.0, 1.0, 1.0, 1.0);
    GL.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT);
    return this.top_node.draw();
  };

  return Logo;

})();

example = new Logo();

params = {
  canvas: 'webgl-canvas',
  context: example,
  init: example.init,
  draw: example.draw,
  debug: true
};

cgl = new PXL.App(params);
