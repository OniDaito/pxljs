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

Basic materials for our ubershader

###

{Material} = require "./material"
{RGBA} = require "../colour/colour"
{uber_uniform_colour, uber_vertex_colour, uber_texture_mat} = require '../gl/uber_shader_paths'


### BasicColourMaterial ###
# A Basic material that is made up of a single colour

class BasicColourMaterial extends Material

  # **constructor**
  # - **colour** - RGB or RGBA

  constructor : (@colour) ->
    super()
    if not @colour.a?
      @colour = new RGBA(@colour.r, @colour.g, @colour.b, 1.0)
    @contract.roles.uColour = "colour"
    @_uber0 = uber_uniform_colour true, @_uber0
    @_uber_defines = ['BASIC_COLOUR']


### VertexColourMaterial ###
# A Basic material that takes the colours from the vertices

class VertexColourMaterial extends Material

  constructor : () ->
    super()
    @_uber0 = uber_vertex_colour true, @_uber0
    @_uber_defines = ['VERTEX_COLOUR']


### TextureMaterial ###
# A Basic material that uses a texture for it its albedo. 

class TextureMaterial extends Material

  @fragment_head : "#ifdef MAT_TEXTURE\nuniform sampler2D uSamplerTexture;\n#endif\n"
  @fragment_main : "#ifdef MAT_TEXTURE\nif(bitcheck(uUber0,4)) { gl_FragColor = texture2D(uSamplerTexture, vTexCoord); }\n#endif\n"

  # **constructor**
  # - **texture** - a Texture
  constructor : (@texture) ->
    super()
    @_uber0 = uber_texture_mat true, @_uber0
    @_uber_defines = ['MAT_TEXTURE', 'VERTEX_TEXTURE']
    @contract.roles.uSamplerTexture  = "texture"

  _preDraw : () ->
    @texture.bind()


module.exports =
  Material : Material
  BasicColourMaterial : BasicColourMaterial
  VertexColourMaterial : VertexColourMaterial
  TextureMaterial : TextureMaterial