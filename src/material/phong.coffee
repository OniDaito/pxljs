###
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

###

{RGB,RGBA} = require "../colour/colour"
{Material} = require "./material"
{Texture} = require "../gl/texture"
{uber_phong_diff_tex, uber_phong_spec_tex, uber_phong_emis_tex, uber_vertex_colour, uber_phong_mat} = require '../gl/uber_shader_paths'

# TODO - transparent alpha blending materials

# We don't reference textures. Rather, textures are sampled and are set to the variable baseColour
# which can either be a texture or a basic passed in colour. This variable is common throughout all
# shaders.

# TODO - eventually most of this will be in a textfile that we process into javascript at build time

# ## PhongMaterial
# A basic material that contains phong elements
# Requires an existing lighting solution, complete with ambient light
# We choose the lights using #ifdef statements that we set thus we can set the different lights

class PhongMaterial extends Material

  # **@constructor**
  # - **ambient** - a Colour.RGB - Default RGB(0,0,0)
  # - **diffuse** - a Colour.RGB or a Texture
  # - **specular** - a Colour.RGB or a Texture - Default RGB(1,1,1)
  # - **shine** - a Number - Default 20
  # - **emissive** -  a Colour.RGB or a Texture - default RGB(0,0,0) 
  constructor: (@ambient, @diffuse, @specular, @shine, @emissive) ->
    super()

    @_uber_defines = ['MATERIAL_PHONG', 'VERTEX_NORMAL', 'ADVANCED_CAMERA']

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
      if @diffuse instanceof RGB or @diffuse instanceof RGBA
        # TODO - Eventually put in materials that are transparent
        @diffuse = new RGB( @diffuse.r, @diffuse.g, @diffuse.b)
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
