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

This software is released under the MIT Licence. See LICENCE.txt for details

###

{RGB,RGBA} = require "../colour/colour"
{Material} = require "./material"
{Texture} = require "../gl/texture"
{uber_phong_diff_tex, uber_phong_spec_tex, uber_phong_emis_tex, uber_vertex_colour, uber_phong_mat} = require '../gl/uber_shader_paths'



# TODO - transparent alpha blending materials

# We don't reference textures. Rather, textures are sampled and are set to the variable baseColour
# which can either be a texture or a basic passed in colour. This variable is common throughout all
# shaders.


### PhongMaterial ###
# A basic material that contains phong elements
# Requires an existing lighting solution, complete with ambient light
# We choose the lights using #ifdef statements that we set thus we can set the different lights

class PhongMaterial extends Material

  @fragment_head : "#ifdef MAT_PHONG\nuniform vec3 uMaterialAmbientColour;\nuniform float uMaterialShininess;\n" +
    "\nuniform vec3 uMaterialDiffuseColour;\n" + 
    "\nuniform sampler2D uSamplerDiffuse;\n" +
    "\nuniform vec3 uMaterialSpecularColour;\n" +
    "\nuniform sampler2D uSamplerSpecular;\n" +
    "\nuniform vec3 uMaterialEmissiveColour;\n" +
    "\nuniform sampler2D uSamplerEmissive;\n#endif\n"

  @fragment_main : "#ifdef MAT_PHONG\nvec3 materialDiffuseColour = uMaterialDiffuseColour;\n" +
    "vec3 materialSpecularColour;\n" +
    "vec3 materialEmissiveColour;\n" +
    "if(bitcheck(uUber0,10)){ materialDiffuseColour = texture2D(uSamplerDiffuse, vTexCoord).rgb;}\n" +
    "materialSpecularColour = uMaterialSpecularColour;\n" +
    "if(bitcheck(uUber0,11)){ materialSpecularColour = texture2D(uSamplerSpecular, vTexCoord).rgb;}\n" +
    "materialEmissiveColour = uMaterialEmissiveColour;\n" +
    "if(bitcheck(uUber0,12)){ materialEmissiveColour = texture2D(uSamplerEmissive, vTexCoord).rgb;}\n" +

    "vec3 specularLightWeighting = vec3(0.0, 0.0, 0.0);\n" +
    "vec3 diffuseLightWeighting = vec3(0.0, 0.0, 0.0);\n" +
    "vec3 materialAmbientColour = uMaterialAmbientColour * uAmbientLightingColour;\n" +
    "gl_FragColor = vec4(materialAmbientColour, 1.0);\n" + 
    "vec3 eyeDirection = normalize(-vPosition.xyz);\n" +
    "#ifdef LIGHTING_POINT\n" +
    "for (int i=0; i < LIGHTING_NUM_POINT_LIGHTS; i++) {\n" +
    # TODO could potentially transform the lights in the vertex shader?
    "  vec3 lightDirection = normalize((uModelMatrix * vec4(uPointLightPos[i],1.0)).xyz - vPosition.xyz);\n" +
    "  vec3 reflectionDirection = reflect(-lightDirection, vTransformedNormal.xyz);\n" +
    "  float specularLightBrightness = pow(max(dot(reflectionDirection, eyeDirection), 0.0), uMaterialShininess);\n" +
    "  specularLightWeighting = specularLightWeighting + (uPointLightColour[i] * specularLightBrightness);\n" +
    "  float diffuseLightBrightness = max(dot(vTransformedNormal.xyz, lightDirection), 0.0);\n" +
    "  diffuseLightWeighting = diffuseLightWeighting + (uPointLightColour[i] * diffuseLightBrightness);\n" +
    "  gl_FragColor += vec4( materialDiffuseColour * diffuseLightWeighting " +
    "   + materialSpecularColour * specularLightWeighting" +
    "   + materialEmissiveColour," +
    "   0.0);\n" +
    "}\n#endif\n#endif\n" 

  constructor: (@ambient, @diffuse, @specular, @shine, @emissive) ->
    super()

    @_uber_defines = ['MAT_PHONG', 'VERTEX_NORMAL', 'ADVANCED_CAMERA']

    @_preDrawCalls = []
    
    @ambient = new RGB(0,0,0) if not @ambient?
  
    @specular = new RGB(1.0,1.0,1.0) if not @specular?
    @shine = 20.0 if not @shine?
    @emissive = new RGB(0.0,0.0,0.0) if not @emissive?

    @contract.roles.uMaterialAmbientColour  = "ambient"
    @contract.roles.uMaterialShininess = "shine"

 
    # Construct the shader chunks depending on what we are passed in.
    # TODO Texture Cube support for phong materials

    # Essentially, given the parameters, we are creating subtly different
    # materials. This way is elegant for the end user but perhaps not so
    # elegant in terms of library. Phong is really a class of materials
    # but at the same time, I dont want to create another factory class just
    # to create textures. Ultimately, all we really care about is whether the 
    # generated shader will be different.

    usingTexture = false

    # If not diffuse assume vertex colours
    # TODO - Finish off vertex diffuse colours
    if not @diffuse?
      @_uber_defines += ['VERTEX_COLOUR']
      @_uber0 = uber_vertex_colour true, @_uber0
    else
      # TODO - Occasionally passing in RGBA causes this to fail. Best put a wrapper
      if @diffuse instanceof RGB
        @contract.roles.uMaterialDiffuseColour  = "diffuse"
        @_uber0 = uber_phong_diff_tex false, @_uber0
      else if @diffuse instanceof Texture
        @diffuse.contract.roles.uSamplerDiffuse = "unit"
        @_preDrawCalls.push () =>
          @diffuse.bind()
        usingTexture = true
        @_uber0 = uber_phong_diff_tex true, @_uber0
      # TODO - Also texture cube  would be good here as well

    if @specular instanceof RGB
      @contract.roles.uMaterialSpecularColour = "specular"
      @_uber0 = uber_phong_spec_tex false, @_uber0
    else if @specular instanceof Texture
      @specular.contract.roles.uSamplerSpecular = "unit"
      @_preDrawCalls.push () =>
          @specular.bind()

      usingTexture = true
      @_uber0 = uber_phong_spec_tex true, @_uber0

    if @emissive instanceof RGB
      @contract.roles.uMaterialEmissiveColour = "emissive"
      @_uber0 = uber_phong_emis_tex false, @_uber0
    else if @emissive instanceof Texture
      @emissive.contract.roles.uSamplerEmissive = "unit"
      @_preDrawCalls.push () =>
        @emissive.bind()

      usingTexture = true
      @_uber0 = uber_phong_spec_tex true, @_uber0

    if usingTexture
      @_uber_defines.push 'VERTEX_TEXTURE'

    @_uber0 = uber_phong_mat true, @_uber0

  # Override to bind textures if there are any
  _preDraw : () ->
    for func in @_preDrawCalls
      func()

module.exports =
  PhongMaterial : PhongMaterial
