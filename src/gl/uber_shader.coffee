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

An Uber shader implementation

TODO - There is an issue that the uber shader will attempt to match its larger contract each time
even with nodes and contracts that dont have related uniforms, because the path through the uber shader
that is being taken doesnt need these uniforms

###

{PhongMaterial} = require "../material/phong"
{TextureMaterial} = require "../material/basic"
{DepthMaterial, ViewDepthMaterial} = require "../material/depth"
{PointLight, SpotLight, AmbientLight} = require "../light/light"
{Shader} = require "./shader"

### UberShader ###
# An implementation of an Ubershader that uses a uniform to choose the path through the shader
# and a series of hash defines to sort out what we actually need
# Hash defines include the following as well as these in the various material classes:
#
# VERTEX_COLOUR
# VERTEX_TEXTURE
# VERTEX_NORMAL
# VERTEX_TANGENT
# VERTEX_NOISE
# VERTEX_TANGENT_FRAME
# VERTEX_SOBEL
#
# FRAGMENT_NOISE
# FRAGMENT_INTENSITY
# FRAGMENT_DEPTH_IN
# FRAGMENT_DEPTH_OUT
# FRAGMENT_LUMINANCE
# FRAGMENT_TANGENT_FRAME
# FRAGMENT_SOBEL
#
# BASIC_COLOUR
# BASIC_CAMERA
# ADVANCED_CAMERA
# SKINNING
# LIGHTING_POINT

# The paths through the shader are defined using the uniform uUber0
# Its a float whose bits are checked. You can see these in uber_shader_paths

# TODO - Potentially have the defines rigidly set in a class?
# TODO - Shaderpaths could do the same - use names that map to numbers

class UberShader extends Shader

  # Functions that can appear in both
  @_noise = "vec3 mod289(vec3 x) {\n" +
    "  return x - floor(x * (1.0 / 289.0)) * 289.0;\n" +
    "}\n\n" +

    "vec4 mod289(vec4 x) {\n" + 
    "  return x - floor(x * (1.0 / 289.0)) * 289.0;\n" +
    "}\n\n" +

    "vec4 permute(vec4 x) {\n" +
    "     return mod289(((x*34.0)+1.0)*x);\n" +
    "}\n\n" +

    "vec4 taylorInvSqrt(vec4 r) {\n" +
    "  return 1.79284291400159 - 0.85373472095314 * r;\n" +
    "}\n\n" +

    "float snoise(vec3 v) {\n" + 
      "const vec2  C = vec2(1.0/6.0, 1.0/3.0) ;\n" +
      "const vec4  D = vec4(0.0, 0.5, 1.0, 2.0);\n" +

      "// First corner\n" +
      "vec3 i  = floor(v + dot(v, C.yyy) );\n" +
      "vec3 x0 =   v - i + dot(i, C.xxx) ;\n" +

      "// Other corners\n" +
      "vec3 g = step(x0.yzx, x0.xyz);\n" +
      "vec3 l = 1.0 - g;\n" +
      "vec3 i1 = min( g.xyz, l.zxy );\n" +
      "vec3 i2 = max( g.xyz, l.zxy );\n" +

      "//   x0 = x0 - 0.0 + 0.0 * C.xxx;\n " +
      "//   x1 = x0 - i1  + 1.0 * C.xxx;\n " +
      "//   x2 = x0 - i2  + 2.0 * C.xxx;\n " +
      "//   x3 = x0 - 1.0 + 3.0 * C.xxx;\n " +
      "vec3 x1 = x0 - i1 + C.xxx;\n" +
      "vec3 x2 = x0 - i2 + C.yyy; // 2.0*C.x = 1/3 = C.y\n" +
      "vec3 x3 = x0 - D.yyy;      // -1.0+3.0*C.x = -0.5 = -D.y\n\n" +

      "// Permutations\n" +
      "i = mod289(i);\n" + 
      "vec4 p = permute( permute( permute( \n" +
      "           i.z + vec4(0.0, i1.z, i2.z, 1.0 ))\n" +
      "         + i.y + vec4(0.0, i1.y, i2.y, 1.0 ))\n" + 
      "         + i.x + vec4(0.0, i1.x, i2.x, 1.0 ));\n\n" +

      "// Gradients: 7x7 points over a square, mapped onto an octahedron.\n" +
      "// The ring size 17*17 = 289 is close to a multiple of 49 (49*6 = 294)\n" +
      "float n_ = 0.142857142857; // 1.0/7.0\n" +
      "vec3  ns = n_ * D.wyz - D.xzx;\n\n" +

      "vec4 j = p - 49.0 * floor(p * ns.z * ns.z);  //  mod(p,7*7)\n\n" + 

      "vec4 x_ = floor(j * ns.z);\n" +
      "vec4 y_ = floor(j - 7.0 * x_ );    // mod(j,N)\n\n" +

      "vec4 x = x_ *ns.x + ns.yyyy;\n" + 
      "vec4 y = y_ *ns.x + ns.yyyy;\n " + 
      "vec4 h = 1.0 - abs(x) - abs(y);\n\n" + 

      "vec4 b0 = vec4( x.xy, y.xy );\n" + 
      "vec4 b1 = vec4( x.zw, y.zw );\n\n" + 

      "//vec4 s0 = vec4(lessThan(b0,0.0))*2.0 - 1.0;\n" + 
      "//vec4 s1 = vec4(lessThan(b1,0.0))*2.0 - 1.0;\n" +
      "vec4 s0 = floor(b0)*2.0 + 1.0;\n" +
      "vec4 s1 = floor(b1)*2.0 + 1.0;\n" +
      "vec4 sh = -step(h, vec4(0.0));\n\n" +

      "vec4 a0 = b0.xzyw + s0.xzyw*sh.xxyy ;\n" +
      "vec4 a1 = b1.xzyw + s1.xzyw*sh.zzww ;\n\n" +

      "vec3 p0 = vec3(a0.xy,h.x);\n" +
      "vec3 p1 = vec3(a0.zw,h.y);\n" +
      "vec3 p2 = vec3(a1.xy,h.z);\n" +
      "vec3 p3 = vec3(a1.zw,h.w);\n\n" +

      "//Normalise gradients\n" +
      "vec4 norm = taylorInvSqrt(vec4(dot(p0,p0), dot(p1,p1), dot(p2, p2), dot(p3,p3)));\n" +
      "p0 *= norm.x;\n" +
      "p1 *= norm.y;\n" +
      "p2 *= norm.z;\n" +
      "p3 *= norm.w;\n\n" +

      "// Mix final noise value\n" +
      "vec4 m = max(0.6 - vec4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 0.0);\n" +
      "m = m * m;\n" +
      "return 42.0 * dot( m*m, vec4( dot(p0,x0), dot(p1,x1),\n" + 
                                    "dot(p2,x2), dot(p3,x3) ) );\n" +
    "}\n"

  # http://www.thetenthplanet.de/archives/1180
  @_tangent_frame = "mat3 computeTangentFrame(vec3 N, vec3 p, vec2 uv) {\n" + 
    " // get edge vectors of the @fragment triangle\n" + 
    " vec3 dp1 = dFdx( p );\n" + 
    " vec3 dp2 = dFdy( p );\n" + 
    " vec2 duv1 = dFdx( uv );\n" + 
    " vec2 duv2 = dFdy( uv );\n" + 
 
    " // solve the linear system\n" + 
    " vec3 dp2perp = cross( dp2, N );\n" + 
    " vec3 dp1perp = cross( N, dp1 );\n" + 
    " vec3 T = dp2perp * duv1.x + dp1perp * duv2.x;\n" + 
    " vec3 B = dp2perp * duv1.y + dp1perp * duv2.y;\n" + 
 
    " // construct a scale-invariant frame \n" + 
    " float invmax = inversesqrt( max( dot(T,T), dot(B,B) ) );\n" + 
    " return mat3( T * invmax, B * invmax, N );\n" + 
    "}\n"

  @_sobel =  "vec3 sobel(float step, vec2 center, float limit) {\n" + 
    "  // get samples around @fragment\n" + 
    "  float tleft = intensity(texture2D(uSampler,center + vec2(-step,step)));\n" + 
    "  float left = intensity(texture2D(uSampler,center + vec2(-step,0)));\n" + 
    "  float bleft = intensity(texture2D(uSampler,center + vec2(-step,-step)));\n" + 
    "  float top = intensity(texture2D(uSampler,center + vec2(0,step)));\n" + 
    "  float bottom = intensity(texture2D(uSampler,center + vec2(0,-step)));\n" + 
    "  float tright = intensity(texture2D(uSampler,center + vec2(step,step)));\n" + 
    "  float right = intensity(texture2D(uSampler,center + vec2(step,0)));\n" + 
    "  float bright = intensity(texture2D(uSampler,center + vec2(step,-step)));\n" + 
   
    "  // Sobel masks (to estimate gradient)\n" + 
    "  //        1 0 -1     -1 -2 -1\n" + 
    "  //    X = 2 0 -2  Y = 0  0  0\n" + 
    "  //        1 0 -1      1  2  1\n" + 
   
    "  float x = tleft + 2.0*left + bleft - tright - 2.0*right - bright;\n" + 
    "  float y = -tleft - 2.0*top - tright + bleft + 2.0 * bottom + bright;\n" + 
    "  float color = sqrt((x*x) + (y*y));\n" + 
    "  if (color < limit){return vec3(0.0,0.0,0.0);}\n" + 
    "  return vec3(1.0,1.0,1.0);\n}\n"

  @_bitcheck = "bool bitcheck(in float fcheck, in int bitpos) { \n" +
  "  int fsi = int(fcheck);\n" +
  "  for (int i = 0; i < 32; i++) { \n" +
  "    if (i >= bitpos) return fract(float(fsi) / 2.0) != 0.0;\n" +
  "    fsi = fsi / 2; \n" +
  "  }\n" + 
  "  return false;\n}\n"

  # VERTEX SHADER

  # HEAD SECTION
  @vertex = "uniform float uUber0;\n"
  @vertex += "attribute vec3 aVertexPosition;\nuniform mat4 uModelMatrix;\nvarying vec4 vPosition;\n"
  @vertex += "#ifdef VERTEX_COLOUR\nattribute vec4 aVertexColour;\nvarying vec4 vColour;\n#endif\n" 
  @vertex += "#ifdef VERTEX_TEXTURE\nattribute vec2 aVertexTexCoord;\nvarying vec2 vTexCoord;\n#endif\n"
  @vertex += "#ifdef BASIC_CAMERA\nuniform mat4 uCameraMatrix;\nuniform mat4 uProjectionMatrix;\n#endif\n"
  @vertex += "#ifdef ADVANCED_CAMERA\nuniform float uCameraNear;\n" +
    "uniform float uCameraFar;\n " +
    "uniform mat4 uCameraInverseMatrix;\n " + 
    "uniform mat4 uInverseProjectionMatrix;\n" +
    "varying vec4 vEyePosition;\n#endif\n" 
  @vertex += "#ifdef VERTEX_NORMAL\nattribute vec3 aVertexNormal;\nvarying vec3 vNormal;\n " + 
    "uniform mat3 uNormalMatrix;\nvarying vec4 vTransformedNormal;\n#endif\n"

  @vertex += "#ifdef VERTEX_TANGENT\n attribute vec3 aVertexTangent;\nvarying vec3 vTangent;\n#endif\n"

  @vertex += "#ifdef SKINNING\n" + 
    "attribute vec4 aVertexSkinWeight;\nattribute vec4 aVertexBoneIndex;\n\n" +
    "uniform sampler2D uBonePalette;\nuniform int uBoneTexDim;\n#endif\n"

  @vertex += PointLight.vertex_head
  @vertex += AmbientLight.vertex_head
  @vertex += SpotLight.vertex_head

  # FUNCTION SECTION
  @vertex += "#ifdef VERTEX_TANGENT_FRAME\n " + UberShader._tangent_frame + "\n#endif\n"
  @vertex += "#ifdef VERTEX_SOBEL\n " + UberShader._sobel + "\n#endif\n"

  @vertex += "#ifdef SKINNING\n" + 
    "vec3 qtransform( vec4 q, vec3 v ){\n" + 
    "  return v + 2.0 * cross(cross(v, q.xyz ) + q.w*v, q.xyz);\n" +
    "}\n\n" +
    "mat4 sample_palette(const in float idx) {\n" +
    "  float tt = float(uBoneTexDim) / 4.0;\n" +
    "  float dd = 1.0 / float(uBoneTexDim);\n" +
    "  float p0 = 0.5 * dd;\n" +
    "  float p1 = 1.0 * dd;\n" +
    "  float p2 = 2.5 * dd;\n" +
    "  float p3 = 3.5 * dd;\n" +
    "  float x = float(mod(idx, tt)) * dd * 4.0;\n" +
    "  float y = floor(float(idx / tt )) * dd;\n" +
    "  vec4 v0 = texture2D(uBonePalette, vec2(x + p0, y + p0));\n" +
    "  vec4 v1 = texture2D(uBonePalette, vec2(x + p1, y + p0));\n" +
    "  vec4 v2 = texture2D(uBonePalette, vec2(x + p2, y + p0));\n" +
    "  vec4 v3 = texture2D(uBonePalette, vec2(x + p3, y + p0));\n" +
    "  mat4 tm = mat4(v0,v1,v2,v3);\n" +
    "  return tm;\n" +
    "}\n#endif\n"

  @vertex += UberShader._bitcheck

  # MAIN SECTION

  # final transform if nothing else
  @vertex += "void main() {\n"
  @vertex += "#ifdef VERTEX_COLOUR\nvColour = aVertexColour;\n#endif\n"
  @vertex += "#ifdef VERTEX_TEXTURE\nvTexCoord = aVertexTexCoord;\n#endif\n"
  @vertex += "#ifdef VERTEX_NORMAL\nvNormal = aVertexNormal;\nvTransformedNormal = vec4(uNormalMatrix * aVertexNormal,1.0);\n#endif\n"
  @vertex += "#ifdef VERTEX_TANGENT\nvTangent = aVertexTangent;\n#endif\n"

  # TODO - could speed up here by elsing with the skinning
  @vertex += "vPosition = uModelMatrix * vec4(aVertexPosition, 1.0);\n"

  @vertex += "#ifdef SKINNING\n" + 
    "if(bitcheck(uUber0,2)) {\n" +
    "  vPosition = vec4(0.0,0.0,0.0,1.0);\n" +
    "  float bias = aVertexSkinWeight.x;\n" +
    "  mat4 tm = sample_palette(aVertexBoneIndex.x);\n" +
    "  vec4 bp = tm * vec4(aVertexPosition,1.0) * bias;\n" +
    "  vPosition += bp;\n" +
    "  bias = aVertexSkinWeight.y;\n" +
    "  tm = sample_palette(aVertexBoneIndex.y);\n" +
    "  bp = tm * vec4(aVertexPosition,1.0) * bias;\n" +
    "  vPosition += bp;\n" +
    "  bias = aVertexSkinWeight.z;\n" +
    "  tm = sample_palette(aVertexBoneIndex.z);\n" +
    "  bp = tm * vec4(aVertexPosition,1.0) * bias;\n" +
    "  vPosition += bp;\n" +
    "  bias = aVertexSkinWeight.w;\n" +
    "  tm = sample_palette(aVertexBoneIndex.w);\n" +
    "  bp = tm * vec4(aVertexPosition,1.0) * bias;\n" +
    "  vPosition += bp;\n" +
    "  vPosition.w = 1.0;\n" +
    "  vPosition = uModelMatrix * vPosition;\n" +
    "}\n" + 
    "\n#endif\n"

  
  @vertex += "#ifdef ADVANCED_CAMERA\n vEyePosition = uCameraInverseMatrix * uModelMatrix * vPosition;\n#endif\n"
  @vertex += "#ifdef BASIC_CAMERA\ngl_Position = uProjectionMatrix * uCameraMatrix * vPosition;\n#endif\n"

  @vertex += "\n}"

  # FRAGMENT SHADER

  # HEAD SECTION of fragment Shader
  @fragment = "uniform float uUber0;\n"
  @fragment += "uniform mat4 uModelMatrix;\nvarying vec4 vPosition;\n"
  @fragment += "#ifdef BASIC_COLOUR\nuniform vec4 uColour;\n#endif\n"
  @fragment += "#ifdef VERTEX_COLOUR\nvarying vec4 vColour;\n#endif\n"
  @fragment += "#ifdef VERTEX_TEXTURE\nvarying vec2 vTexCoord;\n#endif\n"
  @fragment += "#ifdef VERTEX_NORMAL\nuniform mat3 uNormalMatrix;\nvarying vec3 vNormal;\nvarying vec4 vTransformedNormal;\n#endif\n"
  @fragment += "#ifdef VERTEX_TANGENT\nvarying vec3 vTangent;\n#endif\n"
  @fragment += "#ifdef ADVANCED_CAMERA\nuniform float uCameraNear;\n" +
    "uniform float uCameraFar;\n " +
    "uniform mat4 uCameraInverseMatrix;\n " +
    "uniform mat4 uInverseProjectionMatrix;\n" +
    "varying vec4 vEyePosition;\n#endif\n"

  # Materials

  @fragment += PhongMaterial.fragment_head
  @fragment += AmbientLight.fragment_head
  @fragment += PointLight.fragment_head
  @fragment += SpotLight.fragment_head
  @fragment += TextureMaterial.fragment_head
  @fragment += DepthMaterial.fragment_head
  @fragment += ViewDepthMaterial.fragment_head

  # FUNCTION SECTION
  @fragment +="\n\n"
  @fragment +="#ifdef FRAGMENT_NOISE\n" + UberShader._noise + "\n#endif\n"

  @fragment += "#ifdef FRAGMENT_INTENSITY\n" +
    "float intensity(in vec4 colour) {\n" +
    "  return sqrt((colour.x*colour.x)+(colour.y*colour.y)+(colour.z*colour.z));\n" +
    "}\n#endif\n"

  

  @fragment += "#ifdef FRAGMENT_LUMINANCE\n" +
    "float getLuminance(in vec3 colour) {\n"+
    "  vec3 lumcoeff = vec3(0.299,0.587,0.114);\n"+
    "  return dot(colour, lumcoeff);\n}\n#endif\n"

  @fragment += "#ifdef FRAGMENT_TANGENT_FRAME\n " + UberShader._tangent_frame + "\n#endif\n"
  @fragment += "#ifdef FRAGMENT_SOBEL\n " + UberShader._sobel + "\n#endif\n"

  @fragment += UberShader._bitcheck

  # MAIN SECTION

  @fragment += "void main() {\n"
  # materials
  @fragment += PhongMaterial.fragment_main
  @fragment += TextureMaterial.fragment_main

  @fragment += "#ifdef BASIC_COLOUR\nif(bitcheck(uUber0,8)) { gl_FragColor = uColour; }\n#endif\n"
  @fragment += "#ifdef VERTEX_COLOUR\nif(bitcheck(uUber0,9)) { gl_FragColor = vColour; }\n#endif\n"
  @fragment += "#ifdef FRAGMENT_DEPTH_OUT\nif(bitcheck(uUber0,5)) { gl_FragColor = packDepth(); }\n#endif\n"
  @fragment += "#ifdef FRAGMENT_DEPTH_IN\nif(bitcheck(uUber0,6)) { float d = readDepth(vTexCoord);\ngl_FragColor = vec4(d,d,d,1.0); }\n#endif\n"
  @fragment += "\n}"

  # We run over all the nodes, looking for materials. If we have them, check for defines
  # Defines can also occur depending on what we have in the node structure, like point-lights and 
  # such. We therefore do the check for that here, as oppose to inside the node class. Nodes deal with the
  # runtime changes each frame, whereas ubershader deals with defines that should only be needed once :)

  _traverse : (base_node) ->
    if base_node.material?
      for def in base_node.material._uber_defines
        if def not in @uber_defines
          @uber_defines.push def

    # Things to add, depening on whether or not things exist on a node
    if base_node.camera?
      @uber_defines.push "BASIC_CAMERA" if "BASIC_CAMERA" not in @uber_defines
    
    if base_node.pointLights.length > 0
      @uber_defines.push "LIGHTING_POINT" if "LIGHTING_POINT" not in @uber_defines

    if base_node.spotLights.length > 0 
      @uber_defines.push "LIGHTING_SPOT" if "LIGHTING_SPOT" not in @uber_defines
      
      # Checking for shadowmaps
      for light in base_node.spotLights
        if light.shadowmap
          @uber_defines.push "SHADOWMAP" if "SHADOWMAP" not in @uber_defines
          @uber_defines.push "FRAGMENT_DEPTH_OUT" if "FRAGMENT_DEPTH_OUT" not in @uber_defines
    
    if base_node.skeleton?
      @uber_defines.push "SKINNING" if "SKINNING" not in @uber_defines

    for child in base_node.children
      @_traverse child

  # The uberconstructor builds a shader at the base nodes, looking at the entire subtree for all the defines
  # and such that it needs to set.

  # **constructor**
  # - arbitrary number of unnamed arguments - all of class Node 
  constructor : () ->
    @uber_defines = []

    for base_node in arguments
      @_traverse base_node

    def_string = ""
    for def in @uber_defines
      def_string += "#define " + def + "\n"

    # We default to high precision for our ubershader
    # I havent passed in any options for precision yet

    @vertex = "#version 100\n" + "precision highp float;\nprecision highp int;\n" + def_string + UberShader.vertex
    @fragment = "#version 100\n" + "precision highp float;\nprecision highp int;\n" + def_string + UberShader.fragment

    super(@vertex, @fragment, undefined)
    @_uber = true

    for base_node in arguments
      @_addToNode base_node


module.exports =
  UberShader : UberShader
