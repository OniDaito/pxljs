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

{Shader} = require "./shader"
uber = require "../shaders/uber" # this is automatically built via gulp

### UberShader ###
# An implementation of an Ubershader that uses a uniform to choose the path through the shader
# and a series of hash defines to sort out what we actually need.
#
# The paths through the shader are defined using the uniform uUber0
# Its a float whose bits are checked. You can see these in uber_shader_paths

# TODO - Potentially have the defines rigidly set in a class?
# TODO - Shaderpaths could do the same - use names that map to numbers

class UberShader extends Shader

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
      @uber_defines.push "LIGHTING" if "LIGHTING" not in @uber_defines

    if base_node.spotLights.length > 0
      @uber_defines.push "LIGHTING_SPOT" if "LIGHTING_SPOT" not in @uber_defines
      @uber_defines.push "LIGHTING" if "LIGHTING" not in @uber_defines

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

    @vertex = def_string + uber.vertex
    @fragment = def_string + uber.fragment

    super(@vertex, @fragment, undefined)
    @_uber = true

module.exports =
  UberShader : UberShader
