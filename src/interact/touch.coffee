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

util = require "../util/util"
{Vec2} = require "../math/math"
{Signal} = require "../util/signal"

DISTANCE_LIMIT = 1
GESTURE_FLICK_TIME = 280
GESTURE_FLICK_LIMIT = 0.001
FINGER_UP_LIMIT = 60

# ## TouchEmitter
# Attaches to the App / Context and listens for DOM Touch events then emmits

TouchEmitter = {}

TouchEmitter["pauseTouchEmitter"] = (force) ->
  @touchPinch.pause(force)
  @touchTap.pause(force)
  @touchSpread.pause(force)
  @touchFlick.pause(force)
  @touchDrag.pause(force)
  @touchDone.pause(force)


# ## makeTouchEmitter
# function to make an object listen on the dom for touch events
# This function extends another object with many utility functions that deal with 
# touches starting, ending and such. It determines what the gesture may or may not be
# For now, we assume no scrolling at that the view encompasses the entire screen on the 
# touch device (that way we can get the position of the touches correct with the canvas)

makeTouchEmitter = (obj) ->
  if obj.canvas?
    util.extend obj,TouchEmitter

    obj.touchPinch = new Signal()
    obj.touchTap  = new Signal()
    obj.touchSpread   = new Signal()
    obj.touchDrag = new Signal()
    obj.touchFlick = new Signal()
    obj.touchDone = new Signal()
    obj.ongoingTouches = []

    obj._lastTouchTime = Date.now()

    ongoingTouchIndexById = (idToFind) ->
      PXL.Context.switchContext obj
      if obj.ongoingTouches.length > 0
        for i in [0..obj.ongoingTouches.length-1]
          touch = obj.ongoingTouches[i]
          id = touch.identifier

          if id == idToFind
            return i
      
      return -1

    obj["_onTouchStart"] = (evt) =>
      PXL.Context.switchContext obj
      evt.preventDefault()
      touches = evt.changedTouches
      for touch in touches
        idx = ongoingTouchIndexById touch.identifier
        if idx == -1
          touch.ppos = new Vec2 touch.clientX, touch.clientY
          touch.cpos = new Vec2 touch.clientX, touch.clientY
          touch.spos = new Vec2 touch.clientX, touch.clientY
          touch.moved = false
          touch.timeStart = touch.timeNow = touch.timePrev = Date.now();
          obj.ongoingTouches.push touch

      if PXL.Context.debug
        console.log "Touch Start ", obj.ongoingTouches
    
    obj.canvas.ontouchstart = obj["_onTouchStart"]

    obj["_onTouchMove"] = (evt) ->
      PXL.Context.switchContext obj
      evt.preventDefault()
      touches = evt.changedTouches
      
      for newtouch in touches

        idx = ongoingTouchIndexById newtouch.identifier
        touch = obj.ongoingTouches[idx]

        touch.ppos.x = touch.cpos.x
        touch.ppos.y = touch.cpos.y

        touch.cpos.x = newtouch.clientX
        touch.cpos.y = newtouch.clientY
        touch.timePrev = touch.timeNow
        touch.timeNow = Date.now()

        if touch.ppos.x != touch.cpos.x or touch.ppos.y || touch.cpos.y
          touch.moved = true
        else
          touch.moved = false

      # Check for pinch / spread
      if obj.ongoingTouches.length == 2 and touch.moved

        d0 = obj.ongoingTouches[0].cpos.dist(obj.ongoingTouches[1].cpos)
        d1 = obj.ongoingTouches[0].ppos.dist(obj.ongoingTouches[1].ppos)

        evt.ddist = d0 - d1

        dd0 = Vec2.sub obj.ongoingTouches[0].cpos, obj.ongoingTouches[0].ppos
        dd1 = Vec2.sub obj.ongoingTouches[1].cpos, obj.ongoingTouches[1].ppos

        cosa = dd0.dot(dd1) / (dd0.length() * dd1.length())

        if Math.abs(evt.ddist) > DISTANCE_LIMIT
      
          if cosa > 0.5
            # Mostly aligned so two finger swipe
            evt.currentPos = obj.ongoingTouches[0].cpos
            evt.previousPos = obj.ongoingTouches[0].ppos
            evt.fingers = 2
            obj.touchSwipe.dispatch evt
          else

            evt.center = Vec2.add obj.ongoingTouches[0].cpos, obj.ongoingTouches[1].cpos 
            evt.center.multScalar 0.5

            if d0 > d1
              obj.touchSpread.dispatch evt
            else
              obj.touchPinch.dispatch evt

      # Check for swipes with one finger
      else if obj.ongoingTouches.length == 1
        if Date.now() - obj._lastTouchTime > FINGER_UP_LIMIT
          touch = obj.ongoingTouches[0]
          speed = touch.cpos.distanceTo(touch.ppos) / (Date.now() - touch.timeStart)

          if speed <= GESTURE_FLICK_LIMIT or touch.timeNow - touch.timeStart > GESTURE_FLICK_TIME

            if touch.cpos.distanceTo( touch.ppos )  > 0
              evt.currentPos = touch.cpos.copy()
              evt.previousPos = touch.ppos.copy()
              evt.startPos = touch.spos.copy()
              evt.fingers = 1

              # TODO - Potentially use touch.force in this equation to make it more likely?
              obj.touchDrag.dispatch(evt)
  

      #for touch in touches
      #  idx = ongoingTouchIndexById touch.identifier
      #  obj.ongoingTouches.splice idx, 1, touch  # swap in the new touch record
    obj.canvas.ontouchmove = obj["_onTouchMove"]  


    obj["_touchEnd"] = (evt) ->
      PXL.Context.switchContext obj
      evt.preventDefault()
      touches = evt.changedTouches

      if obj.ongoingTouches.length == 1
        if Date.now() - obj._lastTouchTime > FINGER_UP_LIMIT
          tp = new Vec2 touches[0].clientX, touches[0].clientY
          speed = tp.distanceTo(obj.ongoingTouches[0].ppos) / (Date.now() - obj.ongoingTouches[0].timeStart)

          if speed >= GESTURE_FLICK_LIMIT
        
            touch = obj.ongoingTouches[0]
            evt.currentPos = touch.cpos.copy()
            evt.previousPos = touch.ppos.copy()
            evt.startPos = touch.spos.copy()
            evt.fingers = 1
            obj.touchFlick.dispatch(evt)

        for newtouch in touches
          idx = ongoingTouchIndexById(newtouch.identifier)

          if obj.ongoingTouches[idx].moved ==fa lse and Date.now() - obj._lastTouchTime > FINGER_UP_LIMIT
            if PXL.Context.debug
              console.log(evt)

            evt.currentPos = obj.ongoingTouches[idx].cpos.copy()
            evt.fingers = 1
            obj.touchTap.dispatch evt
            
          obj.ongoingTouches.splice(idx, 1)
    
      else

        for newtouch in touches
          idx = ongoingTouchIndexById newtouch.identifier
          obj.ongoingTouches.splice idx, 1
         
        if PXL.Context.debug
          console.log "Touch End ", obj.ongoingTouches

      obj._lastTouchTime = Date.now()

      if obj.ongoingTouches.length == 0
        obj.touchDone.dispatch(evt)

    obj.canvas.ontouchend = obj["_touchEnd"]
    obj.canvas.ontouchcancel = obj["_touchEnd"]

# ## removeTouchEmitter
# - obj - a DOM object - Required
removeTouchEmitter = (obj) ->
  obj.canvas.removeEventListener "touchend", obj["_onTouchEnd"]
  obj.canvas.removeEventListener "touchcancel", obj["_onTouchEnd"]
  obj.canvas.removeEventListener "touchmove", obj["_onTouchMove"]
  obj.canvas.removeEventListener "touchstart", obj["_onTouchStart"]

module.exports = 
  makeTouchEmitter : makeTouchEmitter
  removeTouchEmitter : removeTouchEmitter
