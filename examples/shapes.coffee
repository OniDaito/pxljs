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

An example showing how we create basic shapes

###

class ShapesExample

  init : () ->

    # Create the top node and add our camera
    @top_node = new PXL.Node()  
    @c = new PXL.Camera.MousePerspCamera new PXL.Math.Vec3(0,0,25)
    @top_node.add @c

    # Create a cuboid with a basic material
    # then translate the cube a little
    cube_node = new PXL.Node new PXL.Geometry.Cuboid(new PXL.Math.Vec3(1,2,1))
    cube_node.add new PXL.Material.BasicColourMaterial new PXL.Colour.RGB(1,0,0)
    cube_node.matrix.translate new PXL.Math.Vec3(1,1,3)

    # Create a cylinder with a basic material
    # then translate it a litle
    cylinder_node = new PXL.Node new PXL.Geometry.Cylinder(1,5,2,4)
    cylinder_node.add new PXL.Material.BasicColourMaterial new PXL.Colour.RGB(0,1,0)
    cylinder_node.matrix.translate new PXL.Math.Vec3(-1,0,-3)

    # Create a sphere but add a per-vertex colour
    sphere_node = new PXL.Node new PXL.Geometry.Sphere(1,12,new PXL.Colour.RGBA(0,0,1,1))
    sphere_node.add new PXL.Material.VertexColourMaterial()

    # Alter the first 27 vertices to be red
    for i in [0..27]
      sphere_node.geometry.vertices[i].c = new PXL.Colour.RGBA(1,0,0,1)

    # Add all the nodes to the top node and call our ubershader
    @top_node.add(cube_node).add(cylinder_node).add(sphere_node)
    uber = new PXL.GL.UberShader @top_node
    @top_node.add uber


    # Basic GL Functions
    GL.enable(GL.CULL_FACE)
    GL.cullFace(GL.BACK)
    GL.enable(GL.DEPTH_TEST)

    # Create an angle in radians from degrees
    angle = PXL.Math.degToRad 1
    @rmatrix = new PXL.Math.Matrix4()

    # Create a rotation matrix
    @rmatrix.rotate new PXL.Math.Vec3(1,0,0), angle
    @rmatrix.rotate new PXL.Math.Vec3(0,1,0), angle
    @rmatrix.rotate new PXL.Math.Vec3(0,0,1), angle

  draw : () ->

    # Clear and draw our shapes
    GL.clearColor(0.95, 0.95, 0.95, 1.0)
    GL.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT)
    @top_node.draw()

    # for each child node, multiply its matrix by the rotation matrix
    for n in @top_node.children
      n.matrix.mult @rmatrix



example = new ShapesExample()

params = 
  canvas : 'webgl-canvas'
  context : example
  init : example.init
  draw : example.draw
  debug : true

cgl = new PXL.App params
