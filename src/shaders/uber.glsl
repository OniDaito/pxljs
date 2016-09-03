// The ubershader used in pxljs

##>VERTEX
precision highp float;
precision highp int;

uniform float uUber0;
attribute vec3 aVertexPosition;
uniform mat4 uModelMatrix;
varying vec4 vPosition;

#ifdef VERTEX_COLOUR
attribute vec4 aVertexColour;
varying vec4 vColour;
#endif 

#ifdef VERTEX_TEXTURE
attribute vec2 aVertexTexCoord;
varying vec2 vTexCoord;
#endif

#ifdef BASIC_CAMERA
uniform mat4 uCameraMatrix;
uniform mat4 uProjectionMatrix;
#endif

#ifdef ADVANCED_CAMERA
uniform float uCameraNear;
uniform float uCameraFar;
uniform mat4 uCameraInverseMatrix; 
uniform mat4 uInverseProjectionMatrix;
varying vec4 vEyePosition;
#endif 

#ifdef VERTEX_NORMAL
attribute vec3 aVertexNormal;
varying vec3 vNormal;
uniform mat3 uNormalMatrix;
varying vec4 vTransformedNormal;
#endif

#ifdef VERTEX_TANGENT
attribute vec3 aVertexTangent;
varying vec3 vTangent;
#endif

#ifdef SKINNING 
attribute vec4 aVertexSkinWeight;
attribute vec4 aVertexBoneIndex;
uniform sampler2D uBonePalette;
uniform int uBoneTexDim;
#endif

#ifdef LIGHTING
{{ShaderChunk.ambient_light}}
#endif

#ifdef LIGHTING_POINT
{{ShaderChunk.point_light}}
#endif

#ifdef LIGHTING_SPOT
{{ShaderChunk.spot_light}}
#endif

#ifdef VERTEX_TANGENT_FRAME
{{ShaderChunk.tangent_frame}}
#endif

#ifdef VERTEX_SOBEL
{{ShaderChunk.sobel}}
#endif

#ifdef SKINNING 
vec3 qtransform( vec4 q, vec3 v ){ 
  return v + 2.0 * cross(cross(v, q.xyz ) + q.w*v, q.xyz);
}

mat4 sample_palette(const in float idx) {
  float tt = float(uBoneTexDim) / 4.0;
  float dd = 1.0 / float(uBoneTexDim);
  float p0 = 0.5 * dd;
  float p1 = 1.0 * dd;
  float p2 = 2.5 * dd;
  float p3 = 3.5 * dd;
  float x = float(mod(idx, tt)) * dd * 4.0;
  float y = floor(float(idx / tt )) * dd;
  vec4 v0 = texture2D(uBonePalette, vec2(x + p0, y + p0));
  vec4 v1 = texture2D(uBonePalette, vec2(x + p1, y + p0));
  vec4 v2 = texture2D(uBonePalette, vec2(x + p2, y + p0));
  vec4 v3 = texture2D(uBonePalette, vec2(x + p3, y + p0));
  mat4 tm = mat4(v0,v1,v2,v3);
  return tm;
}
#endif

bool bitcheck(in float fcheck, in int bitpos) { 
  int fsi = int(fcheck);
  for (int i = 0; i < 32; i++) { 
    if (i >= bitpos) return fract(float(fsi) / 2.0) != 0.0;
    fsi = fsi / 2; 
  } 
  return false;
}


void main() {
#ifdef VERTEX_COLOUR
  vColour = aVertexColour;
#endif

#ifdef VERTEX_TEXTURE
  vTexCoord = aVertexTexCoord;
#endif
  
#ifdef VERTEX_NORMAL
  vNormal = aVertexNormal;
  vTransformedNormal = vec4(uNormalMatrix * aVertexNormal,1.0);
#endif

#ifdef VERTEX_TANGENT
  vTangent = aVertexTangent;
#endif

  vPosition = uModelMatrix * vec4(aVertexPosition, 1.0);

#ifdef SKINNING 
  if(bitcheck(uUber0,2)) {
    vPosition = vec4(0.0,0.0,0.0,1.0);
    float bias = aVertexSkinWeight.x;
    mat4 tm = sample_palette(aVertexBoneIndex.x);
    vec4 bp = tm * vec4(aVertexPosition,1.0) * bias;
    vPosition += bp;
    bias = aVertexSkinWeight.y;
    tm = sample_palette(aVertexBoneIndex.y);
    bp = tm * vec4(aVertexPosition,1.0) * bias;
    vPosition += bp;
    bias = aVertexSkinWeight.z;
    tm = sample_palette(aVertexBoneIndex.z);
    bp = tm * vec4(aVertexPosition,1.0) * bias;
    vPosition += bp;
    bias = aVertexSkinWeight.w;
    tm = sample_palette(aVertexBoneIndex.w);
    bp = tm * vec4(aVertexPosition,1.0) * bias;
    vPosition += bp;
    vPosition.w = 1.0;
    vPosition = uModelMatrix * vPosition;
  } 
#endif

  
#ifdef ADVANCED_CAMERA
  vEyePosition = uCameraInverseMatrix * uModelMatrix * vPosition;
#endif

  gl_Position = vPosition;

#ifdef BASIC_CAMERA
  gl_Position = uProjectionMatrix * uCameraMatrix * vPosition;
#endif
}

##>FRAGMENT
precision highp float;
precision highp int;

uniform float uUber0;
uniform mat4 uModelMatrix;
varying vec4 vPosition;

#ifdef BASIC_COLOUR
uniform vec4 uColour;
#endif
  
#ifdef VERTEX_COLOUR
varying vec4 vColour;
#endif
  
#ifdef VERTEX_TEXTURE
varying vec2 vTexCoord;
#endif
  
#ifdef VERTEX_NORMAL
uniform mat3 uNormalMatrix;
varying vec3 vNormal;
varying vec4 vTransformedNormal;
#endif

#ifdef VERTEX_TANGENT
varying vec3 vTangent;
#endif
  
#ifdef ADVANCED_CAMERA
uniform float uCameraNear;
uniform float uCameraFar; 
uniform mat4 uCameraInverseMatrix; 
uniform mat4 uInverseProjectionMatrix;
varying vec4 vEyePosition;
#endif

#ifdef LIGHTING
{{ShaderChunk.ambient_light}}
#endif

#ifdef LIGHTING_POINT
{{ShaderChunk.point_light}}
#endif

#ifdef LIGHTING_SPOT
{{ShaderChunk.spot_light}}
#endif

bool bitcheck(in float fcheck, in int bitpos) { 
  int fsi = int(fcheck);
  for (int i = 0; i < 32; i++) { 
    if (i >= bitpos) return fract(float(fsi) / 2.0) != 0.0;
    fsi = fsi / 2; 
  } 
  return false;
}

{{ShaderChunk.phong_material_fragment_head}}
{{ShaderChunk.texture_material_fragment_head}}
{{ShaderChunk.depth_material_fragment_head}}
{{ShaderChunk.view_material_fragment_head}}

#ifdef FRAGMENT_NOISE
{{ShaderChunk.noise}}
#endif

#ifdef FRAGMENT_INTENSITY
float intensity(in vec4 colour) {
  return sqrt((colour.x*colour.x)+(colour.y*colour.y)+(colour.z*colour.z));
}
#endif

#ifdef FRAGMENT_LUMINANCE
float getLuminance(in vec3 colour) {
  vec3 lumcoeff = vec3(0.299,0.587,0.114);
  return dot(colour, lumcoeff);
}
#endif

#ifdef FRAGMENT_TANGENT_FRAME
{{ShaderChunk.tangent_frame}}
#endif

#ifdef FRAGMENT_SOBEL
{{ShaderChunk.sobel}}
#endif

void main() {
  {{ShaderChunk.phong_material_fragment_main}}
  {{ShaderChunk.texture_material_fragment_main}}

#ifdef BASIC_COLOUR
  if(bitcheck(uUber0,8)) { gl_FragColor = uColour; }
#endif

#ifdef VERTEX_COLOUR
  if(bitcheck(uUber0,9)) { gl_FragColor = vColour; }
#endif
   
#ifdef FRAGMENT_DEPTH_OUT
  if(bitcheck(uUber0,5)) { gl_FragColor = packDepth(); }
#endif

#ifdef FRAGMENT_DEPTH_IN
  if(bitcheck(uUber0,6)) {
    float d = readDepth(vTexCoord);
    gl_FragColor = vec4(d,d,d,1.0); 
  }
#endif

}






