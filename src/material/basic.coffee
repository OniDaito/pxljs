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

{Material} = require "./material"
{RGBA} = require "../colour/colour"
{uber_uniform_colour, uber_vertex_colour, uber_texture_mat} = require '../gl/uber_shader_paths'


# ## BasicColourMaterial
# A Basic material that is made up of a single colour

class BasicColourMaterial extends Material

  # **@constructor**
  # - **colour** - a Colour.RGB or Colour.RGBA

  constructor : (@colour) ->
    super()
    if not @colour?
      @colour = new RGBA.WHITE()
    if not @colour.a?
      @colour = new RGBA(@colour.r, @colour.g, @colour.b, 1.0)
    @contract.roles.uColour = "colour"
    @_uber0 = uber_uniform_colour true, @_uber0
    @_uber_defines = ['BASIC_COLOUR']


# ## VertexColourMaterial
# A Basic material that takes the colours from the vertices

class VertexColourMaterial extends Material

  # **@constructor**
  constructor : () ->
    super()
    @_uber0 = uber_vertex_colour true, @_uber0
    @_uber_defines = ['VERTEX_COLOUR']


# ## TextureMaterial
# A Basic material that uses a texture for it its albedo. 

class TextureMaterial extends Material

  # **constructor**
  # - **texture** - a Texture
  constructor : (@texture) ->
    super()
    @_uber0 = uber_texture_mat true, @_uber0
    @_uber_defines = ['MATERIAL_TEXTURE', 'VERTEX_TEXTURE']
    @contract.roles.uSamplerTexture  = "texture"

  _preDraw : () ->
    @texture.bind()


module.exports =
  Material : Material
  BasicColourMaterial : BasicColourMaterial
  VertexColourMaterial : VertexColourMaterial
  TextureMaterial : TextureMaterial
