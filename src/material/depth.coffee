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

A 'Depth' material. Not a material in the convential sense but render
everything below this using a depth shader instead of any other

###

{Material} = require "./material"
{uber_depth_set, uber_depth_read} = require '../gl/uber_shader_paths'


### DepthMaterial ###
# Render all the nodes below this one using the depth shader 

class DepthMaterial extends Material

  @fragment_head = "#ifdef FRAGMENT_DEPTH_OUT\n" +
            "vec4 pack (float depth) {\n" +
          "  const vec4 bitSh = vec4(256 * 256 * 256,\n"+
          "  256 * 256,\n"+
          "  256,\n"+
          "  1.0);\n"+
          "  const vec4 bitMsk = vec4(0,\n"+
          "   1.0 / 256.0,\n"+
          "   1.0 / 256.0,\n"+
          "   1.0 / 256.0);\n"+
          "   vec4 comp = fract(depth * bitSh);\n"+
          "   comp -= comp.xxyz * bitMsk;\n"+
          "   return comp;\n"+
          "  }\n" +
          "vec4 packDepth() { return pack(gl_FragCoord.z); }\n\n" +
          "// Returns the 3D position in eye space.\n" + 
          "vec3 positionFromDepth(float depth, vec2 texcoord) {\n" +
          "  vec4 position = vec4(texcoord, depth, 1.0);\n" +
          "  position.xyz = position.xyz*2.0 -1.0;\n" +
          "  position = uInverseProjectionMatrix*position;\n" +
          "  position.xyz /= position.w;\n" +
          "  return position.xyz;\n}\n\n" +
          "#endif\n"

  # **constructor**
  constructor : () ->
    super()
    @_override = true
    @_uber0 = uber_depth_set true, @_uber0
    @_uber_defines = ['FRAGMENT_DEPTH_OUT', 'ADVANCED_CAMERA']


### ViewDepthMaterial ###
# Used more for debugging and unpacking the packed depth in the ubershader for viewing on screen

class ViewDepthMaterial extends Material
  @fragment_head = "#ifdef FRAGMENT_DEPTH_IN\n" +
    "uniform sampler2D uSamplerDepth;\n" +
    "float unpack (in vec4 colour) {\n" +
    "  const vec4 bitShifts = vec4(1.0 / (256.0 * 256.0 * 256.0),\n" +
    "    1.0 / (256.0 * 256.0),\n" +
    "    1.0 / 256.0,\n" +
    "    1.0);\n" + 
    "return dot(colour, bitShifts);\n}\n\n"+
    "// Passed in by the coffeegl depth shader. Reproduces from non linear gl_FragCoord.z to linear 0-1\n"+
    "float readDepth(in vec2 coord)  {\n" +
    "  vec4 colour = texture2D(uSamplerDepth, coord);\n"+
    "  float unpacked = unpack(colour);\n" +
    "  return (uCameraNear * unpacked) / ( uCameraFar - unpacked * (uCameraFar - uCameraNear) );\n"+
    "}\n\n" +
    "#endif\n\n"
 

  # **constructor**
  # - **depth_texture** - a Texture
  constructor : (@depth_texture) ->
    super()

    @_override = true
    @_uber0 = uber_depth_read true, @_uber0
    @_uber_defines = ['FRAGMENT_DEPTH_IN', 'ADVANCED_CAMERA', 'VERTEX_TEXTURE']

  _preDraw : () ->
    @depth_texture.bind()

  _postDraw :() ->
    @depth_texture.unbind()

module.exports =
  DepthMaterial : DepthMaterial
  ViewDepthMaterial : ViewDepthMaterial
