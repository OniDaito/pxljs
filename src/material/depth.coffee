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
{uber_depth_set, uber_depth_read} = require '../gl/uber_shader_paths'


# ## DepthMaterial
# Render all the nodes below this one using the depth shader 

class DepthMaterial extends Material

  # **constructor**
  constructor : () ->
    super()
    @_override = true
    @_uber0 = uber_depth_set true, @_uber0
    @_uber_defines = ['FRAGMENT_DEPTH_OUT', 'ADVANCED_CAMERA']


# ## ViewDepthMaterial
# Used more for debugging and unpacking the packed depth in the ubershader for viewing on screen
# Pass in the camera used when the depth material was made to linearise the view properly
class ViewDepthMaterial extends Material
 
  # **constructor**
  # - **depth_texture** - a Texture - Required
  # - **_near** - a Number - Default - 0.1
  # - **_far** - a Number - Default - 10.0
  constructor : (@depth_texture, @_near, @_far) ->
    super()

    @_override = true
    @_uber0 = uber_depth_read true, @_uber0
    @_uber_defines = ['FRAGMENT_DEPTH_IN', 'DEPTH_VIEW_MATERIAL', 'ADVANCED_CAMERA', 'VERTEX_TEXTURE']
      
    @_near = 0.1 if not @_near? 
    @_far = 10.0 if not @_far?

    @contract.roles.uNearDepth  = "_near"
    @contract.roles.uFarDepth  = "_far"

  _preDraw : () ->
    @depth_texture.bind()

  _postDraw :() ->
    @depth_texture.unbind()

module.exports =
  DepthMaterial : DepthMaterial
  ViewDepthMaterial : ViewDepthMaterial
