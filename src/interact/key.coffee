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

###

util = require "../util/util"
{Vec2} = require "../math/math"
{Signal} = require "../util/signal"

###KeyEmitter###
# Attaches to the App / Context and listens for DOM Key events then emmits

KeyEmitter = {}

KeyEmitter["pauseKeyEmitter"] = (force) ->
  @keyUp.pause(force)
  @keyDown.pause(force)
  @keyPress.pause(force)

# makeKeyEmitter - function to make an object listen on the dom for keyboard events
makeKeyEmitter = (obj) ->
  if obj.canvas?
    util.extend obj, KeyEmitter

    obj.keyUp = new Signal()
    obj.keyDown = new Signal()
    obj.keyPress = new Signal()

    obj["_onKeyUp"] = (event) ->
      PXL.Context.switchContext obj
      obj.keyUp.dispatch event
      false

    obj.canvas.addEventListener "keyup", obj["_onKeyUp"]

    obj["_onKeyDown"] = (event) ->
      PXL.Context.switchContext obj
      obj.keyDown.dispatch event
      false

    obj.canvas.addEventListener "keydown", obj["_onKeyDown"]

    obj["_onKeyPress"] = (event) ->
      PXL.Context.switchContext obj
      obj.keyPress.dispatch event
      false

    obj.canvas.addEventListener "keypress", obj["_onKeyPress"]

    
# removeKeyEmitter - remove any keyboard listeners
removeKeyEmitter = (obj) ->
  obj.canvas.removeEventListener('keyup', obj["_onKeyUp"])
  obj.canvas.removeEventListener('keydown', obj["_onKeyDown"])


module.exports = 
  makeKeyEmitter : makeKeyEmitter
  removeKeyEmitter : removeKeyEmitter