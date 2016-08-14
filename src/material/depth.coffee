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

  # **constructor**
  constructor : () ->
    super()
    @_override = true
    @_uber0 = uber_depth_set true, @_uber0
    @_uber_defines = ['FRAGMENT_DEPTH_OUT', 'ADVANCED_CAMERA']


### ViewDepthMaterial ###
# Used more for debugging and unpacking the packed depth in the ubershader for viewing on screen

class ViewDepthMaterial extends Material
 
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
