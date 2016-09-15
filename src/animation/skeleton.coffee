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

A selection of classes that represent a skeleton for Animation
Based largely from the MD5 Parser and the bone structure contained therein

- TODO enforce bone ordering with idx numbers 

###

{Matrix4,Vec2,Vec3,Vec4,Quaternion} = require '../math/math'
{PXLWarning, PXLError, PXLLog} = require '../util/log'
{Contract} = require '../gl/contract'
{CacheVar} = require '../util/cache_var'
{Texture} = require '../gl/texture'


### Bone ### 
# Represents an actual bone. It contains rotations and positions, both absolute and relative
# and the pose positions

class Bone 

  # **@constructor**
  # - **name** - a String - Required
  # - **idx** - a Number - Required - Unique per Skeleton
  # - **parent** - a Bone - may be null
  # - **rotation_pose** - a Quaternion - Required
  # - **position_pose** - a Vec3 - Required

  constructor : (@name, @idx, @parent, @rotation_pose, @position_pose) ->

    if @parent?
      @rotation_relative = Quaternion.invert(@parent.rotation_pose).mult(@rotation_pose)
      @rotation_relative.normalize()

      tp = @position_pose.clone().sub(@parent.position_pose)
      @parent.rotation_pose.transVec3(tp)
      @position_relative = tp

    else
      @rotation_relative = @rotation_pose.clone()
      @position_relative = @position_pose.clone()

  
    @inverse_bind_pose = new Matrix4()
    @inverse_bind_pose.translate(@position_pose).mult(@rotation_pose.getMatrix4())
    @inverse_bind_pose.invert()

    @rotation_global = @rotation_pose.clone()
    @position_global = @position_pose.clone()

    @skinned_matrix = new Matrix4() # Final matrix sent to the shader

    @

  # **rotate ** - Given a quaternion, rotate the bone by that amount
  # - **quat** - A Quaternion
  # TODO - Could put update func in here instead of in draw calls?
  rotate : (quat) ->
    @rotation_relative.multiply(quat).normalize()
    @

### SkinIndex ###
# Nothng more than a way of recording the pair index and count. Used internally by Skin

class SkinIndex
  constructor : (@index, @count) ->
    @    

### SkinWeight ###
# Another pair of values to record how biased the bone is. Used internally by Skin

class SkinWeight
  constructor : (@bone, @bias) ->
    @


### Skin ###
# A collection of weights and indices, based on the md5 model idea. It connects vertices
# to bones basically. It is temporarily used, with the actual skin weights being held
# on vertices

class Skin

  constructor : () ->

    # Index is a list of tuples called index and count
    @index = []

    # Weights is a list of tuples - a link to a bone and a bias
    @weights = []

  addIndex : (skin_index) ->
    @index.push skin_index
    @

  addWeight : (skin_weight) ->
    @weights.push skin_weight
    @

  numWeights : () ->
    @weights.length

  numIndices : () ->
    @index.length


### Skeleton ###
# A skeleton is a relationship of bones

class  Skeleton 

  # Globals, set by the profile in the App class
  @PXL_MAX_BONES_TEX = 256 # How many bones in a skeleton if we use textures
  @PXL_MAX_BONES_UNI = 64 # How many bones in a skeleton if we use uniforms
  @PXL_MAX_WEIGHTS = 4 # How many bones can affect a vertex (set here in stone for now)
  @PXL_MAX_BONES = 128


  # **@constructor**
  # - **root** - a Bone - Required
  constructor : (@root) ->

    @bones = []
    @matrix = new Matrix4()
    # TODO - static sort 

    # A basic contract so we can recurse into the textures and similar
    @contract = new Contract()
    @contract.roles.uBoneTexDim = "_square_dim"
    @_square_dim = Math.sqrt(Skeleton.PXL_MAX_BONES_TEX * 4) # should be 32 :P

    # Check for the required extension
    if PXL?
      if 'OES_texture_float' in PXL.Context.profile.extensions

        # This variable is a texture that saves all the bone positions for the shader
        # TODO Double check the dimensions are correct :)
        @_tdata = new Float32Array Skeleton.PXL_MAX_BONES_TEX * 16

        for i in [0..Skeleton.PXL_MAX_BONES_TEX*4]
          @_tdata[i] = 1

        @_palette = new Texture @_tdata, {width: @_square_dim, height: @_square_dim, channels: GL.RGBA, datatype: GL.FLOAT, min: GL.NEAREST, max : GL.NEAREST } 
        @_palette.contract.roles.uBonePalette = "unit"

      else 
        PXLError "Uniform bone palette support not implemented."


  # Called in the node loop before drawing
  # TODO - Should the user not call the update function? Maybe inkeeping with our 'style'?
  _preDraw : () ->
    @update()
    @_palette.bind()
    @

  _postDraw : ()->
    @_palette.unbind()
    @

  # **addBone** - add a Bone to this skeleton
  # - **bone** - a Bone
  # - returns this
  addBone : (bone) ->
    if @bones.length + 1 < Skeleton.PXL_MAX_BONES
      @bones.push bone
    else
      PXLWarning "Maximum bone limit reached."
    @

  _addToNode: (node) ->
    node.skeleton = @
    @

  # **getBone** - Look through the bones and return the one matching the id
  # - **bone_idx** - a Number - Required
  # - returns either a Bone or null
  getBone : (bone_idx) ->
    for bone in @bones
      if bone.idx == bone_idx
        return bone
    null

  # **getBoneByName** - Get the bone by looking for the one with the matching name
  # - **bone_name** - a String - Required
  # - returns either a Bone or null
  getBoneByName : (bone_name) ->
    for bone in @bones
      if bone.name == bone_name
        return bone
    null

  # **update** - Called to update all the matrices of the various bones
  # We make the assumption that all bones are in order with parents first
  # - returns this
  update : () ->
    
    for b in @bones
      if b.parent is undefined
        b.rotation_global = b.rotation_relative
        b.position_global = b.position_relative
      else
        b.rotation_global.copy(b.parent.rotation_global).mult(b.rotation_relative).normalize()
        tp = b.position_relative.clone()
        tm = Quaternion.invert(b.parent.rotation_global)
        tm.transVec3(tp)
        tp.add(b.parent.position_global)
        b.position_global.copy(tp)

    idx = 0

    for b in @bones
      b.skinned_matrix.identity().translate(b.position_global).mult(b.rotation_global.getMatrix4())
      b.skinned_matrix.mult(b.inverse_bind_pose)
    
      # Update the palette/texture going to the shader
      if PXL?
        for i in [0..15]
          @_tdata[idx * 16 + i] = b.skinned_matrix.a[i]

        idx += 1

    # Update the texture ready for the shader
    if PXL?
      @_palette.update @_tdata

    @

module.exports = 
  Skeleton : Skeleton
  Bone : Bone
  Skin : Skin
  SkinWeight : SkinWeight
  SkinIndex : SkinIndex
