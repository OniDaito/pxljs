### ABOUT
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


###

class Logo

  reset_cubes : () ->
    for cube in @cube_nodes
      cube.matrix.identity()

  arrange_cubes : () ->
    # P
    @cube_nodes[0].matrix.translate( new PXL.Math.Vec3(-4.0,3.0,0.0) )
    @cube_nodes[1].matrix.translate( new PXL.Math.Vec3(-4.0,2.0,0.0) )
    @cube_nodes[2].matrix.translate( new PXL.Math.Vec3(-4.0,1.0,0.0) )
    @cube_nodes[3].matrix.translate( new PXL.Math.Vec3(-4.0,0.0,0.0) )
    @cube_nodes[4].matrix.translate( new PXL.Math.Vec3(-4.0,-1.0,0.0) )
    @cube_nodes[5].matrix.translate( new PXL.Math.Vec3(-4.0,-2.0,0.0) )
    @cube_nodes[6].matrix.translate( new PXL.Math.Vec3(-3.0,3.0,0.0) )
    @cube_nodes[7].matrix.translate( new PXL.Math.Vec3(-2.0,3.0,0.0) )
    @cube_nodes[8].matrix.translate( new PXL.Math.Vec3(-2.0,2.0,0.0) )
    @cube_nodes[9].matrix.translate( new PXL.Math.Vec3(-3.0,1.0,0.0) )
    @cube_nodes[10].matrix.translate( new PXL.Math.Vec3(-2.0,1.0,0.0) )
  
    # X
    @cube_nodes[11].matrix.translate( new PXL.Math.Vec3(-2.0,0.0,0.0) )
    @cube_nodes[12].matrix.translate( new PXL.Math.Vec3(0,0,0) )
    @cube_nodes[13].matrix.translate( new PXL.Math.Vec3(-1.0,-1.0,0.0) )
    @cube_nodes[14].matrix.translate( new PXL.Math.Vec3(-2.0,-2.0,0.0) )
    @cube_nodes[15].matrix.translate( new PXL.Math.Vec3(0.0,-2.0,0.0) )

    # L
    @cube_nodes[16].matrix.translate( new PXL.Math.Vec3(1.0,3.0,0.0) )
    @cube_nodes[17].matrix.translate( new PXL.Math.Vec3(1.0,2.0,0.0) )
    @cube_nodes[18].matrix.translate( new PXL.Math.Vec3(1.0,1.0,0.0) )
    @cube_nodes[19].matrix.translate( new PXL.Math.Vec3(1.0,0.0,0.0) )
    @cube_nodes[20].matrix.translate( new PXL.Math.Vec3(1.0,-1.0,0.0) )
    @cube_nodes[21].matrix.translate( new PXL.Math.Vec3(1.0,-2.0,0.0) )
    @cube_nodes[22].matrix.translate( new PXL.Math.Vec3(2.0,-2.0,0.0) )

  
  rotate_cubes : (dt) ->
    dd = 0
    stopped = true
    for cube in @cube_nodes
      rot = (1.0 + Math.sin(dd)) 
      if cube._rot < 360
        cube._rot += rot
        cube.matrix.rotate new PXL.Math.Vec3(0,1,0), PXL.Math.degToRad(cube._rot) 
        stopped = false
      dd += 0.1

    @time += dt

    if not stopped
      @pause_time = @time
      
    if stopped
      if @time - @pause_time > 5000
        for cube in @cube_nodes
          cube._rot = 0
        @time = 0
        @pause_time = 0  

  init : () ->

    @top_node = new PXL.Node()
  
    @camera = new PXL.Camera.PerspCamera new PXL.Math.Vec3(-6.62, -2.15, 7.29), new PXL.Math.Vec3(-1.17, 0.59, -0.64), new PXL.Math.Vec3(-0.16, 0.96, 0.23)
    @top_node.add @camera

    # Create a cuboid with a basic material
    # then translate the cube a little
    cube_geometry = new PXL.Geometry.CuboidDup(new PXL.Math.Vec3(1,1,1))
    hot_pink = new PXL.Colour.RGB(1.0,0.41,0.7)
    spec = new PXL.Colour.RGB(0.0,0.0,0.0)
    @top_node.add new PXL.Material.PhongMaterial(hot_pink, hot_pink, spec)
 
    # Create a set of nodes for the logo with the same geometry
    @cube_nodes = []
    for i in [0..22]
      cc = new PXL.Node(cube_geometry)
      cc._rot = 0
      @cube_nodes.push cc
      @top_node.add cc  

    @ambientlight = new PXL.Light.AmbientLight(new PXL.Colour.RGB(0.1, 0.1, 0.1))
    @light = new PXL.Light.PointLight new PXL.Math.Vec3(0.0,2.0,6.0), new PXL.Colour.RGB(0.2,0.2,0.2)
    @light2 = new PXL.Light.PointLight new PXL.Math.Vec3(0.0,15.0,5.0), new PXL.Colour.RGB(0.2,0.2,0.2)
    
    @top_node.add @light
    @top_node.add @light2
    @top_node.add @ambientlight

    uber = new PXL.GL.UberShader @top_node
      
    @top_node.add uber

    @time = 0
    @pause_time = 0

    GL.enable(GL.CULL_FACE)
    GL.cullFace(GL.BACK)
    GL.enable(GL.DEPTH_TEST)
  

  draw : (dt) ->
    @reset_cubes()
    @arrange_cubes()
    @rotate_cubes(dt)
    
    GL.clearColor(1.0, 1.0, 1.0, 1.0)
    GL.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT)
    @top_node.draw()


example = new Logo()

params = 
  canvas : 'webgl-canvas'
  context : example
  init : example.init
  draw : example.draw
  debug : true


cgl = new PXL.App params
