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

This file holds the values for our ubershader and some useful functions for setting
the uniform uUber0 that sets the path through the uber shader

At some point these functions will be replace by bit operations (WebGL 3?) or removed
and uniforms and roles will be set per material

###


# Routes through the shader (set by the uniform uUber0) include
# 32 bits we set, with LSB being 0 in this case, on the right
# 0 - flat vertex transform
# 1 - camera vertex transform
# 2 - skinning vertex transform
# 3 - point lights true
# 4 - texture material true
# 5
# 6
# 7 
# 8 - uniform colour true
# 9 - vertex colour true
# 10 - phong diffuse texture true
# 11 - phong specular texture true
# 12 - phong emissive texture true
# 13 - phong material

uber_path_map:
  vertex_flat : 0
  vertex_camera: 1
  vertex_skinning : 2
  lighting_point : 3
  texture_mat : 4
  depth_set : 5
  depth_read: 6
  uniform_colour : 8
  vertex_colour : 9
  phong_diff_tex : 10
  phong_spec_tex : 11
  phong_emis_tex : 12
  phong_mat : 13

# Clear the uber flags for materials as we would like to override in the node
# At the moment, these are 8 to 13 inclusive but WILL change
uber_clear_material = (ubervar) ->
  ubervar & ~0x3F00

# set the tranform to be just straight through
uber_vertex_flat = (tf,ubervar) ->
  if tf
    return ubervar | 0x1
  ubervar & ~0x1

uber_vertex_camera = (tf, ubervar) ->
  if tf
    return ubervar | 0x2
  ubervar & ~0x2

uber_vertex_skinning = (tf, ubervar) ->
  if tf
    return ubervar | 0x4
  ubervar & ~0x4

uber_texture_mat = (tf,ubervar) ->
  if tf
    return ubervar | 0x16
  ubervar & ~0x16

uber_depth_set = (tf,ubervar) ->
  if tf
    return ubervar | 0x20
  ubervar & ~0x20

uber_depth_read = (tf,ubervar) ->
  if tf
    return ubervar | 0x40
  ubervar & ~0x40


uber_lighting_point = (tf, ubervar) ->
  if tf
    return ubervar | 0x8
  ubervar & ~0x8

uber_uniform_colour = (tf,ubervar) ->
  if tf
    return ubervar | 0x100
  ubervar & ~0x100

uber_vertex_colour = (tf,ubervar) ->
  if tf
    return ubervar | 0x200
  ubervar & ~0x200

uber_phong_diff_tex = (tf,ubervar) ->
  if tf
    return ubervar | 0x400
  ubervar & ~0x400

uber_phong_spec_tex = (tf,ubervar) ->
  if tf
    return ubervar | 0x800
  ubervar & ~0x800

uber_phong_emis_tex = (tf,ubervar) ->
  if tf
    return ubervar | 0x1000
  ubervar & ~0x1000

uber_phong_mat = (tf,ubervar) ->
  if tf
    return ubervar | 0x2000
  ubervar & ~0x2000


module.exports = 
  uber_clear_material : uber_clear_material
  uber_vertex_flat : uber_vertex_flat
  uber_vertex_camera : uber_vertex_camera
  uber_vertex_skinning : uber_vertex_skinning
  uber_lighting_point : uber_lighting_point
  uber_uniform_colour : uber_uniform_colour
  uber_vertex_colour : uber_vertex_colour
  uber_phong_diff_tex : uber_phong_diff_tex
  uber_phong_spec_tex : uber_phong_spec_tex
  uber_phong_emis_tex : uber_phong_emis_tex
  uber_phong_mat : uber_phong_mat
  uber_texture_mat : uber_texture_mat
  uber_depth_set: uber_depth_set
  uber_depth_read : uber_depth_read
