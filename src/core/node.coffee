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
{Geometry} = require '../geometry/primitive'
{Contract} = require '../gl/contract'
{PXLWarningOnce} = require '../util/log'
{Front, main_draw} = require './node_paths'

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

    @spotLightShadowMaps = []


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
    front = new Front()
    main_draw(@, front )

 module.exports =
  Node : Node
