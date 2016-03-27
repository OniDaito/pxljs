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
{uber_uniform_colour, uber_vertex_colour} = require '../gl/uber_shader_paths'


###BasicColourMaterial###
# A Basic material that is made up of a single colour

class BasicColourMaterial extends Material

  # Pass in a colour (such as RGB or RGBA) and the material will be that colour
  constructor : (@colour) ->
    super()
    if not @colour.a?
      @colour = new RGBA(@colour.r, @colour.g, @colour.b, 1.0)
    @contract.roles.uColour = "colour"
    @_uber0 = uber_uniform_colour true, @_uber0
    @_uber_defines = ['BASIC_COLOUR']


###VertexColourMaterial###
# A Basic material that takes the colours from the vertices

class VertexColourMaterial extends Material

  constructor : () ->
    super()
    @_uber0 = uber_vertex_colour true, @_uber0
    @_uber_defines = ['VERTEX_COLOUR']

module.exports =
  Material : Material
  BasicColourMaterial : BasicColourMaterial
  VertexColourMaterial : VertexColourMaterial