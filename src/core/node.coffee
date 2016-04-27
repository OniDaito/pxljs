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


Consists of a matrix, a material, parent and children for the scene graph computation
Doesnt have to be drawn per-se

###

{Vec3, Vec4, Matrix3, Matrix4} = require '../math/math'
{matchWithShader} = require '../gl/webgl'
{Camera} = require '../camera/camera'
{Material} = require '../material/material'
{Texture} = require '../gl/texture'
{PointLight, SpotLight} = require '../light/light'
{Geometry} = require '../geometry/primitive'
{Contract} = require '../gl/contract'
{PXLWarningOnce} = require '../util/log'
uber = require '../gl/uber_shader_paths'

util = require '../util/util'

###Node###
# Arguably, the most important piece of code. The node represents the combination of all the
# elements required for drawing. It has a matrix as the minimum, but can also accept materials
# a piece of geometry, a shader and several textures and lights. It can have children but only
# one parent. Nodes form the hierarchy/scene graph for PXL.
# A node has a contract by default but this can be modifed or destroyed. A contract is between
# the node and a shader that is currently bound
# Reserved words, or rather, things that can be added to a node and have special meaning consist of
# - geometry
# - material
# - shader
# - pointLight(s)
# - skeleton

class Node
  
  # Dont have to pass any of these parameters but they will be inspected
  constructor : (@geometry, @material, @shader) ->

    @matrix =  new Matrix4()          # Local matrix for the user to mess with
    @globalMatrix = new Matrix4()     # This is contracted to a shader (global basically)
    @_normalMatrix = new Matrix3()    # Used for the normal matrix should we need it 
    @_mvpMatrix = new Matrix4()       # Combines with the camera to speed up certain operations
    @children = []

    @contract = new Contract()        # Create a contract for this node with the basic contract items
    
    @contract.roles.uModelMatrix      = "globalMatrix"
    @contract.roles.uMVPMatrix        = "_mvpMatrix"      # precomputed model/view/perspective matrix
    @contract.roles.uNormalMatrix     = "_normalMatrix"
    @contract.roles.uUber0            = "_uber0" # The flag for the ubershader if we have one?
    
    @_cached = null                   # TODO A pointer to a cached version of this node. This is invalidated
                                      # if we add or remove nodes to this node or these above

    @pointLights = []
    @spotLights = []

    # TODO - At some point remove textures
    #if not @textures?
    #  @textures = []


  # add - Add things to this node, like geometry, materials or other nodes
  # TODO - we need a flag set here for _dirty and then run shader_automagic again
  add : (p) ->
    p._addToNode?(@)
    @

  # remove - remove a thing from this node
  remove : (p) ->
    p._removeFromNode?(@)
    @

  # private function to add nodes to nodes as children
  _addToNode : (node) ->
    node.children.push @
    @

  # return a copy of this node, referencing any geometry.
  # To duplicate geometry one needs to copy then add a fresh 
  # geometry with new to the new node.
  copy : () ->
    util.clone @


  # Remove from the screen graph
  del : (p) ->
    if p in @children
      i = @children.indexOf(p) 
      @children.splice(i, 1)
    @

  # _removeFromNode - internal. Called when a node is removed from another node
  _removeFromNode : (node) ->
    node.del @
    @

  # draw - Draw the current node and all its children - a recursive call
  # TODO - we should cache the hierarchy, uniforms and textures separately
  # for speed. We shouldnt need to rebuild the hierarchy each time in the main
  # case so this would be a big saving.

  draw : () ->
    # front is an object that represents the cumulated hierarchy at draw time
    front =
      globalMatrix        : new Matrix4()
      pointLights         : []
      spotLights          : []
      _normalMatrix       : new Matrix4()
      _mvpMatrix          : new Matrix4()
      _uber0              : 0
      camera              : undefined
      shader              : undefined
      skeleton            : undefined

    @_draw(@, front )

  # Recursive call to draw. Binds any textures on this node. Sets the lights
  # from the parent nodes, all the way down the tree. This node is then 
  # attempted to be brewed (if it has geometry) and if brewed, it is webgl drawn

  # TODO - Eventually redo this function so we create a set of flat objects with 
  # a cache and all the required info.
  
  # TODO - we will have replacable draw functions depending on the passes we are making
  # This one is the default but there will be other draw passes for things like lights

  _draw: (node, front) ->
    
    front.globalMatrix = Matrix4.mult front.globalMatrix, node.matrix

    # Setup the normal matrix
    nm = node.globalMatrix.copy()

    # Cameras are also passed down the tree but overidden if local
    # Also call update here
    if node.camera?
      front.camera = node.camera
      front.camera.update()
      front._uber0 = uber.uber_vertex_camera true, front._uber0
    
    if front.camera?
      nm = Matrix4.mult(front.camera.m, nm)
      # Create a precomputed model/view/perspective matrix for speed
      front._mvpMatrix.copyFrom nm
      front._mvpMatrix.mult front.camera.m
      front._mvpMatrix.mult front.camera.p
    else
      front._mvpMatrix.copyFrom nm

    # TODO - Normal Matrix calculation better GPU or CPU side? 
    # TODO - We need to be careful about scaling here as well :S
    front._normalMatrix = nm.getMatrix3().invert().transpose()

    for light in node.pointLights
      front.pointLights.push light
    
    uber.uber_lighting_point false, front._uber0
    if node.pointLights.length > 0 
      front._uber0 = uber.uber_lighting_point true, front._uber0
   

    for light in node.spotLights
      front.spotLights.push light
      
    front._uber0 = uber.uber_lighting_spot false, front._uber0
    if node.spotLights.length > 0 
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
    for key of @contract.roles
      if not front[key]?
        front[key] = node[key]

    # Reference the current node contract.
    front.contract = node.contract

    # Actually make the binds with WebGL here.
    # Perhaps better move back to WebGL file?

    # Only draw if we have the context (think tests and the like)
    if PXL.Context.gl?

      gl = PXL.Context.gl

      # Actual Draw
      # Put a line in here to check we also have a shader on the context
      if front.geometry? and front.shader?
      
        # Set the lights here
        PointLight._preDraw front.pointLights
        SpotLight._preDraw front.spotLights

        PXL.Context.shader = front.shader
        PXL.Context.shader.bind()

        matchWithShader front
        # Quick check for unbound uniforms
        if PXL.Context.debug
          for u in PXL.Context.shader.contract.findUnmatched()
            PXLWarningOnce("Unmatched uniform/attribute in shader: " + u.name)
                 
        front.geometry.drawGL()

        # unbind
        PXL.Context.shader.unbind()
        PXL.Context.shader = undefined

    for child in node.children
      # We need to clone front so we dont change it permanently
      # Seems the fastest way is to just copy - json stringify then parse appears not to work
      # TODO - We keep making a copy of this because of the recursive call but surely theres a
      # better way?
      front_child = 
        globalMatrix        : front.globalMatrix.copy()
        pointLights         : front.pointLights.slice(0)
        spotLights          : front.spotLights.slice(0)
        _normalMatrix       : front._normalMatrix.copy()
        _mvpMatrix          : front._mvpMatrix.copy()
        _uber0              : front._uber0
        camera              : front.camera
        shader              : front.shader
        material            : front.material
        contract            : front.contract
        skeleton            : front.skeleton

      @_draw(child, front_child)
    
    # TODO Pre and post draws should probably be in a class or similar? I.e check all members of the 
    # front and see if they have a pre and post
    if front.material?
      front.material._postDraw()

    if front.skeleton?
      front.skeleton._postDraw()

    node

module.exports =
  Node : Node
