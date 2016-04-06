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

# A material represents how a surface reacts to the lighting solution. 
# Each material has a list of shaderChunks that contribute to the final shader

###

{Contract} = require '../gl/contract'

class Material

  constructor : () ->
    @contract = new Contract()
    @_uber0 = 0 # Settings to be OR'd with the ubershader uniform
    @_uber_defines = [] # uber shader looks for this for the defines to add
    @_override = false # if set, this material overides all these below it

  _addToNode : (node) ->
    node.material = @

  # Called if we need to make any GL Calls before drawing with
  #'this material'
  _preDraw : () ->
    @

  _postDraw : () ->
    @

module.exports = 
  Material : Material
