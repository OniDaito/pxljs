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

class CacheVar

  constructor : (@variable) ->
    @dirty = false
    @


  set : (new_value) ->
    if new_value instanceof Array and @variable instanceof Array
      if new_value.length != @variable.length
        @dirty = true
        @variable = new_value
      else
        for i in [0..new_value.length-1]
          if not new_value[i].equals(@variable[i])
            @dirty = true
            @variable = new_value
            return @

    else if new_value.equals?
      if not new_value.equals(@variable)
        @dirty = true
        @variable = new_value

    else if new_value != @variable
      @dirty = true
      @variable = new_value

    @

  get: () ->
    @dirty = false
    @variable

  isDirty: () ->
    @dirty

module.exports =
  CacheVar : CacheVar
