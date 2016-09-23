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

- TODO
* There is no hierarchy or bubbling really. Anyone can listen
* Maybe rethink how we handle events generally? - Game engine style

Influenced by signals.js - an object where listeners and events may be added
###

util = require "./util"
{Vec2} = require "../math/math"

# ## Signal
class Signal

  # **@constructor**
  constructor : () ->
    @listeners = []
    @_pause = false

  # **add** 
  # - **func** - a Function - Required
  # - **context** - an Object - Required
  # - returns this
  add : (func, context) ->
    @listeners.push {f: func, c: context, o: false, g: PXL.Context}
    @
  
  # **addOnce** 
  # - **func** - a Function - Required
  # - **context** - an Object - Required
  # - returns this
  addOnce : (func, context) ->
    @listeners.push {f: func, c: context, o: true, g: PXL.Context}
    @

  # **remove** 
  # - **func** - a Function - Required
  # - **context** - an Object - Required
  # - returns this
  remove : (func, context) ->
    @del func
    @

  # **pause** 
  # - **force** - a Boolean 
  # - returns this
  pause : (force) ->
    if force?
      @_pause = force
    else
      @_pause = !@_pause
    @

  # **del**
  # - **func** - a Function - Required
  # - **context** - an Object - Required 
  # - returns this
  del : (func, context) ->
    for obj in @listeners
      if obj.c == context
        if obj.f == func
          i = @listeners.indexOf(obj) 
          @listeners.splice(i, 1)  
          break
    @

  # **dispatch** the event. All arguments passed in are sent on to the final function
  # - returns this
  dispatch : () ->
    if @_pause
      return @

    removals = []
    for l in @listeners
 
      PXL.Context.switchContext l.g

      l.f.apply(l.c, arguments)
      if l.o
        removals.push l
    
    for l in removals
      @del l

    @

module.exports = 
  Signal : Signal
