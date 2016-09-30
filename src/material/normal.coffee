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
{uber_normal_mat} = require '../gl/uber_shader_paths'

# ## NormalMaterial
# If you want to see the normals on a piece of geometry, this is the material to use

class NormalMaterial extends Material

  # **@constructor**

  constructor : () ->
    super()
    @_uber0 = uber_normal_mat true, @_uber0
    @_uber_defines = ['MATERIAL_NORMAL', 'ADVANCED_CAMERA', 'VERTEX_NORMAL']

module.exports = 
  NormalMaterial : NormalMaterial
 

