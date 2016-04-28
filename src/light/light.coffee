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

Basic forward rendering lights such as ambient, spotlight and such

- TODO 
* Issue arises with timing of shader definitions such as num-lights. Shader will need to 
be rebuilt essentially if the lights change. To do that we have a set of define lines in the
shader which we can modify easily. A user will need to set these if they wish to mess with stuff

*updating the pos and the matrix together :S tricksy

###

{Matrix4, Vec2, Vec3, Vec4} = require '../math/math'
{RGB,RGBA} = require '../colour/colour'
{Contract} = require '../gl/contract'

# These are set in stone and are the actual values passed to the
# shader. Ideally we'd reference them, but the are basically a cache

LIGHTING_NUM_POINT_LIGHTS = 5
LIGHTING_NUM_SPOT_LIGHTS = 5


###AmbientLight###
# Basic ambient lighting. Should be included with all basic lights

class AmbientLight

  @vertex_head : "uniform vec3 uAmbientLightingColour;\n"
  
  @fragment_head : @vertex_head

  constructor : (@colour) ->
    if not @colour?
      @colour = new RGB(0,0,0)

    @contract = new Contract()
    @contract.roles.uAmbientLightingColour = "colour"

  _addToNode: (node) ->
    # Overwrite and give no warning?
    node.ambientLight = @
    @


### PointLight ###
# A very basic light, a point in space. Used by the node class at present
# Doesnt create shadows at present (might use a different class for that)
# TODO - At some point this class will need to detect forward and deferred
# lighting solutions.
# The static class if you will, of PointLight (the protoype) keeps a record
# of all the lights in the system and it is this which is passed to the uber
# shader in the end. That way, they can be passed as arrays and looped over

class PointLight

  @vertex_head : "#ifdef LIGHTING_POINT\n" +
    "#define LIGHTING_NUM_POINT_LIGHTS " + LIGHTING_NUM_POINT_LIGHTS  + "\n" +
    "uniform int uPointLightNum;\n" +
    "uniform vec3 uPointLightPos[LIGHTING_NUM_POINT_LIGHTS];\n" +
    "uniform vec3 uPointLightColour[LIGHTING_NUM_POINT_LIGHTS];\n" +
    "uniform vec4 uPointLightAttenuation[LIGHTING_NUM_POINT_LIGHTS];\n" +
    "#endif\n"

  @fragment_head : @vertex_head

 
  @_posGlobal = new Float32Array(LIGHTING_NUM_POINT_LIGHTS * 3)
  @_colourGlobal = new Float32Array(LIGHTING_NUM_POINT_LIGHTS * 3)
  @_attenuationGlobal =  new Float32Array(LIGHTING_NUM_POINT_LIGHTS * 4)

  @contract = new Contract()
  @contract.roles.uPointLightPos = "_posGlobal"
  @contract.roles.uPointLightColour = "_colourGlobal"
  @contract.roles.uPointLightAttenuation = "_attenuationGlobal"
  @contract.roles.uPointLightNum = "_numGlobal"

  # Called by the node traversal section when we create our node tree

  @_preDraw : (lights) ->

    idx = 0
    if not lights?
      return

    for light in lights
      # Light transforms are now done in the shader
      PointLight._posGlobal[idx * 3] = light.pos.x
      PointLight._posGlobal[idx * 3 + 1] = light.pos.y
      PointLight._posGlobal[idx * 3 + 2] = light.pos.z

      PointLight._colourGlobal[idx * 3] = light.colour.r
      PointLight._colourGlobal[idx * 3 + 1] = light.colour.g
      PointLight._colourGlobal[idx * 3 + 2] = light.colour.b

      PointLight._attenuationGlobal[idx * 4] = light.attenuation.x
      PointLight._attenuationGlobal[idx * 4 + 1] = light.attenuation.y
      PointLight._attenuationGlobal[idx * 4 + 2] = light.attenuation.z
      PointLight._attenuationGlobal[idx * 4 + 3] = light.attenuation.w

    PointLight._numGlobal = lights.length


  # constructor -  takes a position (Vec3), a colour, and a set of attenuation factors ([float,float,float,float])
  constructor : (@pos, @colour, @attenuation) ->
   
    # this is a bit of a hack to get things bound to shaders but it works
    @contract = PointLight.contract
    @_posGlobal = PointLight._posGlobal
    @_colourGlobal = PointLight._colourGlobal
    @_attenuationGlobal = PointLight._attenuationGlobal
    @_numGlobal = PointLight._numGlobal

    if not @pos?
      @pos = new Vec3(1,1,1)
    
    if not @colour?
      @colour = RGB.WHITE()

    # Attention has 4 components - range, constant, linear and quadratic
    if not @attenuation?
      @attenuation = [ 100, 1.0, 0.045, 0.0075 ]


  # _addToNode - called when this class is added to a node
  _addToNode: (node) ->
    node.pointLights.push @
    @

  # _removeFromNode - called when this class is removed from a node
  _removeFromNode: (node) ->
    node.pointLights.splice node.pointLights.indexOf @
    @


### SpotLight ###
# A SpotLight with a direction and angle (which represents how wide the beam is)
# Just as in PointLight, the spotlight prototype records all spots
class SpotLight

  @vertex_head : "#ifdef LIGHTING_SPOT\n" +
    "#define LIGHTING_NUM_SPOT_LIGHTS " + LIGHTING_NUM_SPOT_LIGHTS  + "\n" +
    "uniform int uSpotLightNum;\n" +
    "uniform vec3 uSpotLightPos[LIGHTING_NUM_SPOT_LIGHTS];\n" +
    "uniform vec3 uSpotLightColour[LIGHTING_NUM_SPOT_LIGHTS];\n" +
    "uniform vec3 uSpotLightDir[LIGHTING_NUM_SPOT_LIGHTS];\n" + # TODO - if normalised can reduce down - optimise
    "uniform vec4 uSpotLightAttenuation[LIGHTING_NUM_SPOT_LIGHTS];\n" +
    "uniform float uSpotLightAngle[LIGHTING_NUM_SPOT_LIGHTS];\n" +
    "uniform float uSpotLightExp[LIGHTING_NUM_SPOT_LIGHTS];\n" +
    "#ifdef SHADOWMAP\nuniform sampler2D uSamplerPointShadow[LIGHTING_NUM_SPOT_LIGHTS];\n#endif\n" +
    "#endif\n"

  @fragment_head : @vertex_head


  @_posGlobal = new Float32Array(LIGHTING_NUM_SPOT_LIGHTS * 3)
  @_colourGlobal = new Float32Array(LIGHTING_NUM_SPOT_LIGHTS * 3)
  @_attenuationGlobal = new Float32Array(LIGHTING_NUM_SPOT_LIGHTS * 4)
  @_dirGlobal = new Float32Array(LIGHTING_NUM_SPOT_LIGHTS * 3)
  @_angleGlobal = new Float32Array(LIGHTING_NUM_SPOT_LIGHTS)
  @_expGlobal = new Float32Array(LIGHTING_NUM_SPOT_LIGHTS)

  @contract = new Contract()
  @contract.roles.uSpotLightPos = "_posGlobal"
  @contract.roles.uSpotLightColour = "_colourGlobal"
  @contract.roles.uSpotLightAttenuation = "_attenuationGlobal"
  @contract.roles.uSpotLightDir = "_dirGlobal"
  @contract.roles.uSpotLightAngle = "_angleGlobal"
  @contract.roles.uSpotLightExp = "_expGlobal"
  @contract.roles.uSpotLightNum = "_numGlobal"

  # called internally - sets up the global contract array
  @_preDraw : (lights) ->
    idx = 0
    
    if not lights?
      return
    
    for light in lights
      SpotLight._posGlobal[idx * 3] = light.pos.x
      SpotLight._posGlobal[idx * 3 + 1] = light.pos.y
      SpotLight._posGlobal[idx * 3 + 2] = light.pos.z

      SpotLight._colourGlobal[idx * 3] = light.colour.r
      SpotLight._colourGlobal[idx * 3 + 1] = light.colour.g
      SpotLight._colourGlobal[idx * 3 + 2] = light.colour.b

      SpotLight._attenuationGlobal[idx * 4] = light.attenuation.x
      SpotLight._attenuationGlobal[idx * 4 + 1] = light.attenuation.y
      SpotLight._attenuationGlobal[idx * 4 + 2] = light.attenuation.z
      SpotLight._attenuationGlobal[idx * 4 + 3] = light.attenuation.w
      
      SpotLight._dirGlobal[idx * 3] = light.dir.x
      SpotLight._dirGlobal[idx * 3 + 1] = light.dir.y
      SpotLight._dirGlobal[idx * 3 + 2] = light.dir.z

      SpotLight._angleGlobal[idx] = light.angle
      SpotLight._expGlobal[idx] = light.exponent
      
      idx += 1

    SpotLight.numGlobal = lights.length


  # TODO - Add a mask here that basically says which lights are on or off
  # We need this because we may call draw on a subnode of a node that has a light
  # and that light should not affect the scene. this mask would be passed to the shader

  # **constructor** 
  # -**pos** - a Vec3
  # -**colour** - an RGB
  # -**dir** - a Vec3
  # -**angle** - a Number - radians
  # -**exponent** - a Number
  # -**shadowmap** - a Boolean
  # -**attentuation** - a List of Number - length 4 - optional - default [100, 1.0, 0.045, 0.0075]
  constructor : (@pos, @colour, @dir, @angle, @exponent, @shadowmap,  @attenuation) ->

    @contract = SpotLight.contract

    @_posGlobal = SpotLight._posGlobal
    @_colourGlobal = SpotLight._colourGlobal
    @_attenuationGlobal = SpotLight._attenuationGlobal
    @_dirGlobal = SpotLight._dirGlobal
    @_angleGlobal = SpotLight._angleGlobal
    @_expGlobal = SpotLight._expGlobal
    
    if not @pos?
      @pos = new Vec3(1,1,1)
    
    if not @colour?
      @colour = RGB.WHITE()

    if not @shadowmap?
      @shadowmap = false

    if @shadowmap
      @_shadowmap_fbo = new Fbo(640,640,GL.R)

    # Attenuation has 4 components - range, constant, linear and quadratic
    if not @attenuation?
      @attenuation = [ 100, 1.0, 0.045, 0.0075 ]
  
    if not @dir?
      @dir = new Vec3(0,-1,0)

    @dir.normalize()

    if not @angle?
      @angle = 45.0
    
    if not @exponent?
      @exponent = 100.0

    @idx = -1 # Used to say where in the global array this light is

   
  # _addToNode - called when this class is added to a node
  _addToNode: (node) ->
    node.spotLights.push @
    @

  # _removeFromNode - called when this class is removed from a node
  _removeFromNode: (node) ->
    node.spotLights.splice node.spotLights.indexOf @
    @



module.exports =
  PointLight : PointLight
  AmbientLight : AmbientLight
  SpotLight : SpotLight
