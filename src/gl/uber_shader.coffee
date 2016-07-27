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

An Uber shader implementation

TODO - There is an issue that the uber shader will attempt to match its larger contract each time
even with nodes and contracts that dont have related uniforms, because the path through the uber shader
that is being taken doesnt need these uniforms

###

{PhongMaterial} = require "../material/phong"
{TextureMaterial} = require "../material/basic"
{DepthMaterial, ViewDepthMaterial} = require "../material/depth"
{PointLight, SpotLight, AmbientLight} = require "../light/light"
{Shader} = require "./shader"

### UberShader ###
# An implementation of an Ubershader that uses a uniform to choose the path through the shader
# and a series of hash defines to sort out what we actually need
# Hash defines include the following as well as these in the various material classes:
#
# VERTEX_COLOUR
# VERTEX_TEXTURE
# VERTEX_NORMAL
# VERTEX_TANGENT
# VERTEX_NOISE
# VERTEX_TANGENT_FRAME
# VERTEX_SOBEL
#
# FRAGMENT_NOISE
# FRAGMENT_INTENSITY
# FRAGMENT_DEPTH_IN
# FRAGMENT_DEPTH_OUT
# FRAGMENT_LUMINANCE
# FRAGMENT_TANGENT_FRAME
# FRAGMENT_SOBEL
#
# BASIC_COLOUR
# BASIC_CAMERA
# ADVANCED_CAMERA
# SKINNING
# LIGHTING_POINT

# The paths through the shader are defined using the uniform uUber0
# Its a float whose bits are checked. You can see these in uber_shader_paths

# TODO - Potentially have the defines rigidly set in a class?
# TODO - Shaderpaths could do the same - use names that map to numbers

class UberShader extends Shader



  # final transform if nothing else
  # FRAGMENT SHADER

  # HEAD SECTION of fragment Shader
  # Materials
  # FUNCTION SECTION


  # MAIN SECTION

  # We run over all the nodes, looking for materials. If we have them, check for defines
  # Defines can also occur depending on what we have in the node structure, like point-lights and 
  # such. We therefore do the check for that here, as oppose to inside the node class. Nodes deal with the
  # runtime changes each frame, whereas ubershader deals with defines that should only be needed once :)

  _traverse : (base_node) ->
    if base_node.material?
      for def in base_node.material._uber_defines
        if def not in @uber_defines
          @uber_defines.push def

    # Things to add, depening on whether or not things exist on a node
    if base_node.camera?
      @uber_defines.push "BASIC_CAMERA" if "BASIC_CAMERA" not in @uber_defines
    
    if base_node.pointLights.length > 0
      @uber_defines.push "LIGHTING_POINT" if "LIGHTING_POINT" not in @uber_defines

    if base_node.spotLights.length > 0 
      @uber_defines.push "LIGHTING_SPOT" if "LIGHTING_SPOT" not in @uber_defines
      
      # Checking for shadowmaps
      for light in base_node.spotLights
        if light.shadowmap
          @uber_defines.push "SHADOWMAP" if "SHADOWMAP" not in @uber_defines
          @uber_defines.push "FRAGMENT_DEPTH_OUT" if "FRAGMENT_DEPTH_OUT" not in @uber_defines
    
    if base_node.skeleton?
      @uber_defines.push "SKINNING" if "SKINNING" not in @uber_defines

    for child in base_node.children
      @_traverse child

  # The uberconstructor builds a shader at the base nodes, looking at the entire subtree for all the defines
  # and such that it needs to set.

  # **constructor**
  # - arbitrary number of unnamed arguments - all of class Node 
  constructor : () ->
    @uber_defines = []

    for base_node in arguments
      @_traverse base_node

    def_string = ""
    for def in @uber_defines
      def_string += "#define " + def + "\n"

    # We default to high precision for our ubershader
    # I havent passed in any options for precision yet

    @vertex = "#version 100\n" + "precision highp float;\nprecision highp int;\n" + def_string + UberShader.vertex
    @fragment = "#version 100\n" + "precision highp float;\nprecision highp int;\n" + def_string + UberShader.fragment

    super(@vertex, @fragment, undefined)
    @_uber = true

    for base_node in arguments
      @_addToNode base_node


module.exports =
  UberShader : UberShader
