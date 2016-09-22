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


A set of draw paths for the node - effectively render paths
###

{Vec3, Vec4, Matrix3, Matrix4} = require '../math/math'
{matchWithShader} = require '../gl/webgl'
{Camera, PerspCamera} = require '../camera/camera'
{Material} = require '../material/material'
{DepthMaterial} = require "../material/depth"
{Texture} = require '../gl/texture'
{PointLight, SpotLight} = require '../light/light'
{Geometry} = require '../geometry/primitive'
{Contract} = require '../gl/contract'
{PXLWarningOnce} = require '../util/log'
uber = require '../gl/uber_shader_paths'

util = require '../util/util'


### Front ###
# A stripped down version of the Node Class that just copies the data, and amalgamates
# node data as we traverse the tree
# There is a problem here - as we change node, what happen to front? Better design needed here?

class Front
  # **@constructor** 
  constructor : () ->

    @globalMatrix =  new Matrix4()
    @pointLights = []
    @spotLights  =  []
    @_normalMatrix =  new Matrix4()
    @_mvpMatrix = new Matrix4()
    @_uber0 = 0
    @camera = undefined
    @shader = undefined
    @skeleton = undefined

  clone : () ->
    c = new Front()

    # These are copied which suggests a potential
    # for modifying down the tree
    c.globalMatrix.copy @globalMatrix
    c.pointLights = @pointLights.slice(0)
    c.spotLights = @spotLights.slice(0)
    c._normalMatrix.copy @_normalMatrix
    c._mvpMatrix.copy @_mvpMatrix
    c._uber0 = @_uber0
    
    # These are references which reflects the 
    # behaviour that cameras, shaders etc, override
    # when when progress down the tree - should
    # be made more explicit perhaps
    c.camera = @camera
    c.shader = @shader
    c.material = @material
    c.contract = @contract
    c.skeleton = @skeleton

    c

# TODO - this should really live somewhere else
_shadow_map_material = new DepthMaterial()
_shadow_map_camera = new PerspCamera new Vec3(0,1,0), new Vec3(0,0,0), new Vec3(1,0,0), 3.0, 0.1, 100.0

# **shadomap_create_draw**
# -**node** - a Node
# -**front** - An Object based on Node
# -**light** - a SpotLight (eventually all lights)

# Called when we find a spotLight that casts shadows
# A Camera should have been set on the front before this function is called - dont like that :S

shadowmap_create_draw = (node,front,light) -> 

  fc = front.clone()
  # Create the camera we shall use
  # Shouldnt really do this all the time if not needed :S
  # Rather than recreate this matrix in the shader, we pass it in as a uniform for now
  # This will be awkward as we are setting values on node objects and looking at modelviews
  # and all the rest. Very cross cutting this ><

  _shadow_map_camera.pos.copy light.pos
  _shadow_map_camera.look.copy Vec3.add(light.pos, light.dir)
  _shadow_map_camera.up.copy Vec3.perp(light.dir)
  _shadow_map_camera.angle = light.angle
  #_shadow_map_camera.near = 0.1
  _shadow_map_camera.far = light.attenuation[0]
  fc.camera = _shadow_map_camera

  # Create the inverse matrix making sure to multiply by the current modelview matrix
  icm = front.globalMatrix.clone()
  icm.mult _shadow_map_camera.m
  icm.mult _shadow_map_camera.p
  #icm.invert()
  light.invMatrix.copy icm

  # Begin the creation of a shadowmap for this light source
  light.shadowmap_fbo.bind()
  fc.camera.update()
  GL.clearColor(0.0, 0.0, 0.0, 0.0)
  GL.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT)
  _shadowmap_create_draw node, fc, light
  light.shadowmap_fbo.unbind()


# **_shadowmap_create_draw **
# Internal recursive function

_shadowmap_create_draw = (node, front, light) ->
  
  front.globalMatrix = Matrix4.mult front.globalMatrix, node.matrix

  nm = node.globalMatrix.clone()

  front.material = _shadow_map_material
  front.material._preDraw()

  front._uber0 = front.material._uber0
  #front._uber0 = uber.uber_depth_set true, front._uber0
  front._uber0 = uber.uber_vertex_camera true, front._uber0

  # Sort of assuming we have a nice ubershader already
  # Not needed I believe as the shader should exist on front before it's cloned and passed in
  #if node.shader?
  #  front.shader = node.shader
  
  # Create a precomputed model/view/perspecti:ve matrix for speed
  nm = Matrix4.mult(front.camera.m, nm)
 
  # Possibly only needs to be done when we actually need to draw or bind
  front._mvpMatrix.copy nm
  front._mvpMatrix.mult front.camera.m
  front._mvpMatrix.mult front.camera.p

  front._normalMatrix = nm.getMatrix3().invert().transpose()

  if node.geometry?
    if not node.geometry.brewed
      node.geometry.brew()
    front.geometry = node.geometry

  # This contract probably needs a lot of trimming given the material we 
  # are using and nothing else

  for key of node.contract.roles
    if not front[key]?
      front[key] = node[key]

  front.contract = node.contract

  # Pass down skeletons
  if node.skeleton?
    node.skeleton._preDraw()
    front.skeleton = node.skeleton
    front._uber0 = uber.uber_vertex_skinning true, front._uber0

  # Only draw if we have the context (think tests and the like)
  if PXL.Context.gl?

    # Actual Draw
    # Put a line in here to check we also have a shader on the context
    if front.geometry? and front.shader?

      PXL.Context.shader = front.shader
      PXL.Context.shader.bind()

      matchWithShader(front)

      # Quick check for unbound uniforms
      if PXL.Context.debug
        for u in PXL.Context.shader.contract.findUnmatched()
          PXLWarningOnce("Unmatched uniform/attribute in shader: " + u.name)
               
      front.geometry.drawGL()


  for child in node.children
    # We need to clone front so we dont change it permanently
    # Seems the fastest way is to just copy - json stringify then parse appears not to work
    # TODO - We keep making a copy of this because of the recursive call but surely theres a
    # better way?
    front_child = front.clone()
    _shadowmap_create_draw(child, front_child, light)
    
  node

# Recursive call to draw. Binds any textures on this node. Sets the lights
# from the parent nodes, all the way down the tree. This node is then 
# attempted to be brewed (if it has geometry) and if brewed, it is webgl drawn

# TODO - Eventually redo this function so we create a set of flat objects with 
# a cache and all the required info.
  
# **main_draw**
# -**node** - a Node
# -**front** - An Object based on Node
main_draw = (node, front) ->
    
  front.globalMatrix = Matrix4.mult front.globalMatrix, node.matrix

  # Setup the normal matrix
  nm = node.globalMatrix.clone()

  # Cameras are also passed down the tree but overidden if local
  # Also call update here
  if node.camera?
    front.camera = node.camera
    front.camera.update()
    front._uber0 = uber.uber_vertex_camera true, front._uber0
  
  if front.camera?
    nm = Matrix4.mult(front.camera.m, nm)
    # Create a precomputed model/view/perspective matrix for speed
    front._mvpMatrix.copy nm
    front._mvpMatrix.mult front.camera.m
    front._mvpMatrix.mult front.camera.p

  # TODO - Normal Matrix calculation better GPU or CPU side? 
  # TODO - We need to be careful about scaling here as well :S
  front._normalMatrix = nm.getMatrix3().invert().transpose()

  for light in node.pointLights
    front.pointLights.push light
  
  if node.pointLights.length > 0
    front._uber0 = uber.uber_lighting_point true, front._uber0
  
  for light in node.spotLights
    # shadowmap jumping off point
    if light.shadowmap
      if PXL.Context.gl?
        shadowmap_create_draw node, front, light
        front.spotLights.push light
     
      front._uber0 = uber.uber_shadowmap true, front.uber0 # we want shadowmapping

    front._uber0 = uber.uber_lighting_spot true, front._uber0
  
  # Overwrite the ambient if there is one closer
  # TODO - combine perhaps?
  if node.ambientLight?
    front.ambientLight = node.ambientLight

  # Shaders are passed down - if this node has no shader, one further up the
  # chain must already be bound but we bind late
  # TODO We should check if a user one is bound :S
  if node.shader?
    front.shader = node.shader
  
  # TODO - Do we need all these if checks? Just copy null?

  if node.geometry?
    if not node.geometry.brewed
      node.geometry.brew()
    front.geometry = node.geometry

  # Pass down skeletons
  if node.skeleton?
    node.skeleton._preDraw()
    front.skeleton = node.skeleton
    front._uber0 = uber.uber_vertex_skinning true, front._uber0

  # Material - Call predraw
  # Materials are inherited but certain ones cannot be overridden
  if node.material?
    if (front.material? and not front.material._override) or not front.material?
        node.material._preDraw()
        front.material = node.material
        front._uber0 = uber.uber_clear_material(front._uber0) | node.material._uber0
        
  # Copy any user contract items (added to the contract) that have not already been added
  # as users can add data to be passed in the contract (like uColour).
  # Do this by reference for now.
  for key of node.contract.roles
    if not front[key]?
      front[key] = node[key]

  # Reference the current node contract.
  front.contract = node.contract

  # Actually make the binds with WebGL here.
  # Perhaps better move back to WebGL file?

  # Only draw if we have the context (think tests and the like)
  if PXL.Context.gl?

    # Actual Draw
    # Put a line in here to check we also have a shader on the context
    if front.geometry?
    
      if front.shader?      
        PXL.Context.shader = front.shader
    
      if PXL.Context.shader?
        # Set the lights here
        PointLight._preDraw front.pointLights
        SpotLight._preDraw front.spotLights

        PXL.Context.shader.bind()

        matchWithShader(front)
        # Quick check for unbound uniforms
        if PXL.Context.debug
          for u in PXL.Context.shader.contract.findUnmatched()
            PXLWarningOnce("Unmatched uniform/attribute in shader: " + u.name)
               
        front.geometry.drawGL()

        # unbind - TODO - do we really need to unbind?
        PXL.Context.shader.unbind()
        PXL.Context.shader = undefined

  for child in node.children
    # We need to clone front so we dont change it permanently
    # Seems the fastest way is to just copy - json stringify then parse appears not to work
    # TODO - We keep making a copy of this because of the recursive call but surely theres a
    # better way?
    front_child = front.clone()
    main_draw(child, front_child)
  
  # TODO Pre and post draws should probably be in a class or similar? I.e check all members of the 
  # front and see if they have a pre and post
  if front.material?
    front.material._postDraw()

  if front.skeleton?
    front.skeleton._postDraw()

  node


module.exports =
  Front : Front
  main_draw : main_draw
