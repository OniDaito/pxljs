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

###AmbientLight###
# Basic ambient lighting. Should be included with all basic lights

class AmbientLight

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

class PointLight

  @vertex_head : "#ifdef LIGHTING_POINT\n" +
    "uniform vec3 uAmbientLightingColour;\n" +
    "#define LIGHTING_NUM_POINT_LIGHTS " + LIGHTING_NUM_POINT_LIGHTS  + "\n" +
    "uniform int uPointLightNum;\n" +
    "uniform vec3 uPointLightPos[LIGHTING_NUM_POINT_LIGHTS];\n" +
    "uniform vec3 uPointLightColour[LIGHTING_NUM_POINT_LIGHTS];\n" +
    "uniform vec4 uPointLightAttenuation[LIGHTING_NUM_POINT_LIGHTS];\n" +
    "#endif\n"

  @fragment_head : @vertex_head

 

  @posGlobal = new Float32Array(LIGHTING_NUM_POINT_LIGHTS * 3)
  @colourGlobal = new Float32Array(LIGHTING_NUM_POINT_LIGHTS * 3)
  @attenuationGlobal = new Float32Array(LIGHTING_NUM_POINT_LIGHTS * 4)
  @numLightsGlobal = 0

  # TODO - Add a mask here that basically says which lights are on or off
  # We need this because we may call draw on a subnode of a node that has a light
  # and that light should not affect the scene. this mask would be passed to the shader

  # constructor -  takes a position (Vec3), a colour, and a set of attenuation factors ([float,float,float,float])
  constructor : (@pos, @colour, @attenuation) ->

    if not @pos?
      @pos = new Vec3(1,1,1)
    
    if not @colour?
      @colour = RGB.WHITE()

    # Attention has 4 components - range, constant, linear and quadratic
    if not @attenuation?
      @attenuation = [ 100, 1.0, 0.045, 0.0075 ]

    @idx = -1 # Used to say where in the global array this light is

    # TODO - This is a tad wasteful. We should only need one static contract for all lights
    @contract = new Contract()
    @contract.roles.uPointLightPos = "_posGlobal"
    @contract.roles.uPointLightColour = "_colourGlobal"
    @contract.roles.uPointLightAttenuation = "_attenuationGlobal"

    # We give each light a reference to the static variables to make
    # contract matching easier

    @_posGlobal = PointLight.posGlobal
    @_colourGlobal = PointLight.colourGlobal
    @_attenuationGlobal = PointLight.attenuationGlobal

  # _addToNode - called when this class is added to a node
  _addToNode: (node) ->
    if PointLight.numLightsGlobal < LIGHTING_NUM_POINT_LIGHTS 
      node.pointLights.push @
      @idx = PointLight.numLightsGlobal
      PointLight.numLightsGlobal += 1 
    else
      PXLWarning("Number of point lights is at maximum: " + LIGHTING_NUM_POINT_LIGHTS)
    @


  # Called by the node traversal section when we create our node tree

  _preDraw : (gmatrix) ->

    # Light transforms are now done in the shader
    PointLight.posGlobal[@idx * 3] = @pos.x
    PointLight.posGlobal[@idx * 3 + 1] = @pos.y
    PointLight.posGlobal[@idx * 3 + 2] = @pos.z

    PointLight.colourGlobal[@idx * 3] = @colour.r
    PointLight.colourGlobal[@idx * 3 + 1] = @colour.g
    PointLight.colourGlobal[@idx * 3 + 2] = @colour.b

    PointLight.attenuationGlobal[@idx * 4] = @attenuation.x
    PointLight.attenuationGlobal[@idx * 4 + 1] = @attenuation.y
    PointLight.attenuationGlobal[@idx * 4 + 2] = @attenuation.z
    PointLight.attenuationGlobal[@idx * 4 + 3] = @attenuation.w


  # _removeFromNode - called when this class is removed from a node
  _removeFromNode: (node) ->
    node.pointLights.splice node.pointLights.indexOf @
    if PointLight.numLightsGlobal > 0
      PointLight.numLightsGlobal -= 1
    @idx = -1
    @


module.exports = 
  PointLight : PointLight
  AmbientLight : AmbientLight
