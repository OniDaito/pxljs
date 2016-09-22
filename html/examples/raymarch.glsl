##>VERTEX
precision highp float;
precision highp int;

// Defaults for PXLjs
attribute vec3 aVertexPosition;
uniform mat4 uModelMatrix;
varying vec4 vPosition;

void main(void) {
  gl_Position = vec4(aVertexPosition, 1.0);
}

##>FRAGMENT
precision highp float;
precision highp int;

// Largely derived from:
// - https://www.shadertoy.com/view/XsXGDH
// - http://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm

uniform vec3 uResolution;
uniform float uGlobalTime; // In seconds
uniform vec4 uMouse;
uniform sampler2D uChannel0; // Usually noise?
uniform vec4 uDate;

const float hitThreshold = 0.001;
const int maxSteps = 60;
const int shadowSteps = 64;

// Noise Functions

#ifndef HIGH_QUALITY_NOISE 
float noise( in vec2 x ) {
  //return texture2D( uChannel0, (x+0.5)/256.0 ).x;

  vec2 p = floor(x);
  vec2 f = fract(x);
  vec2 uv = p.xy + f.xy*f.xy*(3.0-2.0*f.xy);

  return texture2D( uChannel0, (uv+0.5)/256.0, -100.0 ).x;
}

float noise( in vec3 x ) {
  vec3 p = floor(x);
  vec3 f = fract(x);
  f = f*f*(3.0-2.0*f);
  
  vec2 uv = (p.xy+vec2(37.0,17.0)*p.z) + f.xy;
  vec2 rg = texture2D( uChannel0, (uv+0.5)/256.0, -100.0 ).yx;
  
  return mix( rg.x, rg.y, f.z );
}
#else
float noise( in vec2 x ) {
    vec2 p = floor(x);
    vec2 f = fract(x);

  f =  f*f*(3.0-2.0*f);

  float a = texture2D( uChannel0, (p+vec2(0.5,0.5))/256.0, -100.0 ).x;
  float b = texture2D( uChannel0, (p+vec2(1.5,0.5))/256.0, -100.0 ).x;
  float c = texture2D( uChannel0, (p+vec2(0.5,1.5))/256.0, -100.0 ).x;
  float d = texture2D( uChannel0, (p+vec2(1.5,1.5))/256.0, -100.0 ).x;

  return mix( mix( a, b, f.x ), mix( c, d, f.x ), f.y );

}

float noise( in vec3 x ) {
  vec3 p = floor(x);
  vec3 f = fract(x);
  f = f*f*(3.0-2.0*f);
  
  vec2 uv = (p.xy+vec2(37.0,17.0)*p.z);
  vec2 rga = texture2D( uChannel0, (uv+vec2(0.5,0.5))/256.0, -100.0 ).yx;
  vec2 rgb = texture2D( uChannel0, (uv+vec2(1.5,0.5))/256.0, -100.0 ).yx;
  vec2 rgc = texture2D( uChannel0, (uv+vec2(0.5,1.5))/256.0, -100.0 ).yx;
  vec2 rgd = texture2D( uChannel0, (uv+vec2(1.5,1.5))/256.0, -100.0 ).yx;
  
  vec2 rg = mix( mix( rga, rgb, f.x ),
           mix( rgc, rgd, f.x ), f.y );
  
  return mix( rg.x, rg.y, f.z );
}
#endif

float hash( float n ) {
    return fract(sin(n)*43758.5453123);
}

// Rotation Functions

// transforms
vec3 rotateX(vec3 p, float a){
    float sa = sin(a);
    float ca = cos(a);
    return vec3(p.x, ca*p.y - sa*p.z, sa*p.y + ca*p.z);
}

vec3 rotateY(vec3 p, float a) {
    float sa = sin(a);
    float ca = cos(a);
    return vec3(ca*p.x + sa*p.z, p.y, -sa*p.x + ca*p.z);
}

vec3 rotateZ(vec3 p, float a) {
    float sa = sin(a);
    float ca = cos(a);
    return vec3(ca*p.x - sa*p.y, sa*p.x + ca*p.y, p.z);
}

// Distance Functions
// http://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm

float sdPlane( vec3 p, vec4 n ) {
  // n must be normalized
  return dot(p,n.xyz) + n.w;
}

float udRoundBox( vec3 p, vec3 b, float r ) {
  return length(max(abs(p)-b,0.0))-r;
}

float sdSphere( vec3 p, float s ) {
  return length(p)-s;
}

// Operations 
vec3 opTx (mat4 m, vec3 p){
  vec4 q = m * vec4(p,1.0);
  return q.xyz;
}

float opU( float d1, float d2 ) {
    return min (d1, d2);
}

mat3 rotationMat(vec3 v, float angle) {
  float c = cos(angle);
  float s = sin(angle);
  
  return mat3(c + (1.0 - c) * v.x * v.x, (1.0 - c) * v.x * v.y - s * v.z, (1.0 - c) * v.x * v.z + s * v.y,
    (1.0 - c) * v.x * v.y + s * v.z, c + (1.0 - c) * v.y * v.y, (1.0 - c) * v.y * v.z - s * v.x,
    (1.0 - c) * v.x * v.z - s * v.y, (1.0 - c) * v.y * v.z + s * v.x, c + (1.0 - c) * v.z * v.z
    );
}

// based on gluLookAt
mat4 lookAt(vec3 eye, vec3 center, vec3 up) {
  vec3 z = normalize(eye - center);
  vec3 y = up;
  vec3 x = cross(y, z);
  y = cross(z, x);
  x = normalize(x);
  y = normalize(y);
  mat4 rm = mat4(x.x, y.x, z.x, 0.0,  // 1st column
             x.y, y.y, z.y, 0.0,
               x.z, y.z, z.z, 0.0,
           0.0, 0.0, 0.0, 1.0);
  mat4 tm = mat4(1.0);
  tm[3] = vec4(-eye, 1.0);
  return rm * tm;
       
}

// Warped plane
float warpPlane (vec3 p) {
  vec2 position=(gl_FragCoord.xy/ uResolution.xy);

  vec4 plane_normal = vec4(0, 1, 0, 1);

  float d = sdPlane( p, plane_normal );

  vec3 tex = texture2D(uChannel0,p.xz * 0.1).rgb;
  float intensity = (tex.r + tex.b + tex.g) / 3.0;

  float nn = (sin( uGlobalTime + p.x) *  sin( uGlobalTime + p.z) + intensity) * 0.3;
  return d + nn;
}


// Scene itself - sum all the distance fields with operations and away we go.

float scene(vec3 p) {   
  float t = uGlobalTime * 1.5;
  
  float d;  
  mat3 m = rotationMat(vec3(0.0,1.0,0.0), t);

  d = sdSphere(p,1.0);
  d = opU(warpPlane(p), d);
  d = opU(udRoundBox( m * p, vec3(2.0,0.5,0.5), 0.1),d);

  return d;
}



vec3 sceneNormal(in vec3 pos ) {
    float eps = 0.0001;
    vec3 n;
    float d = scene(pos);
    n.x = scene( vec3(pos.x+eps, pos.y, pos.z) ) - d;
    n.y = scene( vec3(pos.x, pos.y+eps, pos.z) ) - d;
    n.z = scene( vec3(pos.x, pos.y, pos.z+eps) ) - d;
    return normalize(n);
}

float ambientOcclusion(vec3 p, vec3 n) {
    const int steps = 4;
    const float delta = 0.5;

    float a = 0.0;
    float weight = 1.0;
    for(int i=1; i<=steps; i++) {
        float d = (float(i) / float(steps)) * delta; 
        a += weight*(d - scene(p + n*d));
        weight *= 0.5;
    }
    return clamp(1.0 - a, 0.0, 1.0);
}

// http://iquilezles.org/www/articles/rmshadows/rmshadows.htm
float softShadow(vec3 ro, vec3 rd, float mint, float maxt, float k) {
    float dt = (maxt - mint) / float(shadowSteps);
    float t = mint;
  t += hash(ro.z*574854.0 + ro.y*517.0 + ro.x)*0.1;
    float res = 1.0;
    for( int i=0; i<shadowSteps; i++ )
    {
        float h = scene(ro + rd*t);
    if (h < hitThreshold) return 0.0; // hit
        res = min(res, k*h/t);
        //t += h;
    t += dt;
    }
    return clamp(res, 0.0, 1.0);
}

// lighting
vec3 shade(vec3 pos, vec3 n, vec3 eyePos) {
  //vec3 color = vec3(0.5);
  //const vec3 lightDir = vec3(0.577, 0.577, 0.577);
  //vec3 v = normalize(eyePos - pos);
  //vec3 h = normalize(v + lightDir);
  //float diff = dot(n, lightDir);
  //diff = max(0.0, diff);
  //diff = 0.5+0.5*diff;
  
  float ao = ambientOcclusion(pos, n);
  //vec3 c = diff*ao*color;
  

  // skylight
  vec3 sky = mix(vec3(0.3, 0.2, 0.0), vec3(0.6, 0.8, 1.0), n.y*0.5+0.5);
  vec3 c = sky*0.5 * ao;
  
  // point light
  /*
  const vec3 lightPos = vec3(5.0, 5.0, 5.0);
  const vec3 lightColor = vec3(0.5, 0.5, 0.1);
  
  vec3 l = lightPos - pos;
  float dist = length(l);
  l /= dist;
  float diff = max(0.0, dot(n, l));
  //diff *= 50.0 / (dist*dist); // attenutation
  
#if 1
  float maxt = dist;
    float shadow = softShadow( pos, l, 0.1, maxt, 5.0 );
  diff *= shadow;
#endif
  
  c += diff*lightColor;
  */
//  
//  return n*0.5+0.5;
  return c;
}

// Nice background colour
vec3 background(vec3 rd){
  return mix(vec3(0.3, 0.2, 0.0), vec3(0.6, 0.8, 1.0), rd.y*0.5+0.5);
}



// Main Entry

void main() { 
  
  // Ray Cast
  vec2 position=(gl_FragCoord.xy/uResolution.xy);
  vec2 p = -1.0 +2.0 * position; // Normalized 2D position
  vec3 ray_dir = normalize(vec3(p,1.0)); // screen ratio (x,y) fov (z)
  vec3 ray_origin = vec3(0.0, 0.0, -8.0);
  vec3 ray_pos = ray_origin;

  // rotation of camera

  vec2 mouse = uMouse.xy / uResolution.xy;
  float roty = 0.0; //-1.0 + mouse.x * 2.0;
  float rotx = 0.0; //-1.0 + mouse.y * 2.0;

  ray_dir = rotateX(ray_dir, rotx);
  ray_origin = rotateX(ray_origin, rotx);
    
  ray_dir = rotateY(ray_dir, roty);
  ray_origin = rotateY(ray_origin, roty);
 
  float d = scene(ray_pos);
  float dd = d;
  float c = 0.0;
  vec3 rgb = background(ray_dir);
  bool hit = false;

  // Trace! :D

  for (int i=0; i < maxSteps; i ++){
    if (!hit){
      ray_pos += (ray_dir * dd);    
      d = scene(ray_pos);

      if (abs(d) < hitThreshold){
        vec3 n = sceneNormal(ray_pos);
        rgb = shade(ray_pos, n, ray_origin);
        hit = true;
      }
      dd = d;
    }
  }

  gl_FragColor = vec4(rgb,1.0); 

}
