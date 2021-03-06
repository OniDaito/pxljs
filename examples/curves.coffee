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



init = () ->

  # Our basic polygon
	p0 = new PXL.Math.Vec3(50,350,0)
	p1 = new PXL.Math.Vec3(100,300,0)
	p2 = new PXL.Math.Vec3(200,300,0)
	p3 = new PXL.Math.Vec3(200,500,0)
	p4 = new PXL.Math.Vec3(400,480,0)
	p5 = new PXL.Math.Vec3(350,320,0)
	p6 = new PXL.Math.Vec3(500,100,0)
	p7 = new PXL.Math.Vec3(200,50,0)

	polygon = [p0,p1,p2,p3,p4,p5,p6,p7]

	white = new PXL.Colour.RGBA.WHITE()

	# The vertices of the polygon / sites
 
	v0 = new PXL.Geometry.Vertex
		p : p0
		c : white
 
	v1 = new PXL.Geometry.Vertex
		p : p1
		c : white 

	v2 = new PXL.Geometry.Vertex
		p : p2
		c : white 

	v3 = new PXL.Geometry.Vertex
		p : p3
		c : white 

	v4 = new PXL.Geometry.Vertex
		p : p4
		c : white 

	v5 = new PXL.Geometry.Vertex
		p : p5
		c : white 

	v6 = new PXL.Geometry.Vertex
		p : p6
		c : white

	v7 = new PXL.Geometry.Vertex
		p : p7
		c : white 

	polygon_shape = new PXL.Geometry.VertexSoup( [v0,v1,v2,v3,v4,v5,v6,v7] )
	polygon_shape.layout = GL.LINE_LOOP

  # Create a Catmull Rom Spline from this data

	colour_spline = new PXL.Colour.RGBA(0.0,1.0,1.0,0.8)
	spline = new PXL.Math.CatmullRomSpline( polygon )
	spline_verts = []

	for i in [1..500]
		spline_verts.push new PXL.Geometry.Vertex 
			p : spline.pointOnCurve(i/500.0)
			c : colour_spline

	@spline_shape = new PXL.Geometry.VertexSoup spline_verts
	@spline_shape.layout = GL.LINE_STRIP

	# Create a catmull patch

	patch_points = []

	for i in [0..15]
		patch_points.push new PXL.Math.Vec3((i % 4)-1.5, 0.0, Math.floor(i/4)-1.5)

	patch_points[5].y = 1.0
	patch_points[6].y = 1.0
	patch_points[9].y = 1.0
	patch_points[10].y = 1.0

	@catmull_patch = new PXL.Math.CatmullPatch(patch_points)

	# Now sample our patch
	res = 100
	@persp_node = new PXL.Node
	patch_geometry = new PXL.Geometry.PlaneFlat(res,res)

	for i in [0..patch_geometry.p.length-1]
		xi = (i % res) / res
		yi = Math.floor(i/res) / res

		ny = @catmull_patch.sample(new PXL.Math.Vec2(xi,yi))
		patch_geometry.p[i*3] = ny.x
		patch_geometry.p[i*3+1] = ny.y
		patch_geometry.p[i*3+2] = ny.z

	patch_geometry.layout = GL.LINE_STRIP
	@persp_node.add patch_geometry

	vertexMaterial = new PXL.Material.VertexColourMaterial()
	@persp_node.add vertexMaterial


	# Now setup all the nodes and shaders 
	@ortho_node = new PXL.Node
	@ortho_node.add vertexMaterial

	@polygon_node = new PXL.Node
	@polygon_node_lines = new PXL.Node polygon_shape
	@polygon_node.add polygon_node_lines

	@spline_node = new PXL.Node @spline_shape
  
	@ortho_node.add @polygon_node
	@ortho_node.add @spline_node

	@ortho_camera = new PXL.Camera.OrthoCamera(new PXL.Math.Vec3(0,0,0.2), new PXL.Math.Vec3(0,0,0))
	@ortho_node.add @ortho_camera

	@persp_camera = new PXL.Camera.MousePerspCamera(new PXL.Math.Vec3(0,1,6), new PXL.Math.Vec3(0,0,0))
	@persp_node.add @persp_camera
 
	uber = new PXL.GL.UberShader @persp_node, @ortho_node
	@persp_node.add uber
	@ortho_node.add uber

	GL.enable GL.DEPTH_TEST
	GL.blendFunc GL.SRC_ALPHA, GL.ONE

draw = () ->
  
  GL.clearColor(0.15, 0.15, 0.15, 1.0)
  GL.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT)

  GL.lineWidth(1.0)

  @ortho_node.draw()
  @persp_node.draw()

params = 
  canvas : 'webgl-canvas'
  context : @
  init : init
  draw : draw

cgl = new PXL.App params
