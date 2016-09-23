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

{Contract} = require '../gl/contract'

# ## Material
# A base class for materials
class Material

  # **@constructor** 
  constructor : () ->
    @contract = new Contract()

    # TODO - these are per class not instance so we can change that
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
