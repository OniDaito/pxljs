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


### MouseEmitter ###
# Attaches to the App / Context and listens for DOM Mouse events then emmits

MouseEmitter = {}

MouseEmitter["pauseMouseEmitter"] = (force) ->
  @mouseMove.pause(force)
  @mouseDown.pause(force)
  @mouseUp.pause(force)
  @mouseClick.pause(force)
  @mouseOut.pause(force)
  @mouseOver.pause(force)
  @mouseWheel.pause(force)

MouseEmitter["_setMouseEvent"] = (event) ->
  @_getMousePos event
  @_setButtons event

  event.preventDefault() if event.preventDefault?
  event.stopImmediatePropagation() if event.stopImmediatePropagation?
  event.stopPropagation() if event.stopPropagation?
  event

MouseEmitter["_getMousePos"] = (e) ->

  # Create a mouseX and mouseY on our event, cross platform and browser

  if e.clientX or e.clientY
    e.mouseX = e.clientX
    e.mouseY = e.clientY

  else if e.offsetX or e.offsetY
    e.mouseX = e.offsetX
    e.mouseY = e.offsetY

  [e.mouseX,e.mouseY]

MouseEmitter["_setButtons"] = (event) ->
  # Set the buttons for easier recognition - also, different browsers may report this differently
  # IE Will no doubt report this differently

  if event.type == "mousedown"
    @_mouseButton = true

  else if event.type == "mouseup" or  event.type == "mouseout"
    @_mouseButton = false


  if PXL.Context.profile.browser == "Firefox"
    if event.type == "mousemove" and event.buttons != 0
      @_mouseButton = true

  if @_mouseButton

    if PXL.Context.profile.browser == "Firefox"

      if (event.button == 0 and event.buttons == 1) or event.buttons == 1
        event.buttonLeft = true
        event.buttonMiddle = false
        event.buttonRight = false
        event

      else if (event.button == 1 and event.buttons == 4) or event.buttons == 4
        event.buttonLeft = false
        event.buttonMiddle = true
        event.buttonRight = false
        event

      else if (event.button == 2 and event.buttons == 2) or event.buttons == 2
        event.buttonLeft = false
        event.buttonMiddle = false
        event.buttonRight = true
        event
    else
      if event.button == 0
        event.buttonLeft = true
        event.buttonMiddle = false
        event.buttonRight = false
        event

      else if event.button == 1
        event.buttonLeft = false
        event.buttonMiddle = true
        event.buttonRight = false
        event

      else if event.button == 2
        event.buttonLeft = false
        event.buttonMiddle = false
        event.buttonRight = true
        event

  else
    event.buttonLeft = false
    event.buttonMiddle = false
    event.buttonRight = false
    event


### makeMouseEmitter ###
# function to make an object listen on the dom for mouse events
makeMouseEmitter = (obj) ->
  if obj.canvas?
    util.extend obj, MouseEmitter

    obj.mouseMove  = new Signal()
    obj.mouseDown  = new Signal()
    obj.mouseUp    = new Signal()
    obj.mouseClick = new Signal()
    obj.mouseOut   = new Signal()
    obj.mouseOver  = new Signal()
    obj.mouseWheel = new Signal()
    obj["_mouseButton"] = false
    
    obj["_onMouseMove"] = (event) ->
      PXL.Context.switchContext obj
      e = obj._setMouseEvent event
      obj.mouseMove.dispatch e
      false

    obj.canvas.onmousemove = obj["_onMouseMove"]

    obj["_onMouseDown"] = (event) ->
      PXL.Context.switchContext obj
      obj._setMouseEvent event
      obj.mouseDown.dispatch event
      false

    obj.canvas.onmousedown = obj["_onMouseDown"]

    obj["_onMouseUp"] = (event) ->
      PXL.Context.switchContext obj
      obj._setMouseEvent event
      obj.mouseUp.dispatch event
      false

    obj.canvas.onmouseup = obj["_onMouseUp"]

    obj["_onMouseClick"] = (event) ->
      PXL.Context.switchContext obj
      obj._setMouseEvent event
      obj.mouseClick.dispatch event
      false

    obj.canvas.onmouseclick = obj["_onMouseClick"]

    obj["_onContextMenu"] = (event) ->
      PXL.Context.switchContext obj
      obj._setMouseEvent event
      false

    obj.canvas.oncontextmenu = obj["_onContextMenu"]

    obj["_onMouseOut"]= (event) ->
      PXL.Context.switchContext obj
      obj._setMouseEvent event
      obj.mouseOut.dispatch event
      false
    obj.canvas.onmouseout = obj["_onMouseOut"]

    obj["_onMouseOver"] = (event) ->
      PXL.Context.switchContext obj
      obj._setMouseEvent event
      obj.mouseOver.dispatch event
      false

    obj.canvas.onmouseover = obj["_onMouseOver"]


    if obj.canvas.addEventListener?

      # Dealing with the lack of event in Firefox
      obj["_onMouseWheel"] = (event) =>
        PXL.Context.switchContext obj
        obj._setMouseEvent event
        obj.mouseWheel.dispatch event
        false

      obj["_onDOMNouseScroll"]  = (event) =>
        PXL.Context.switchContext obj
        event.wheelDelta = Math.max(-500, Math.min(500, (event.wheelDelta || -event.detail) * 500))
        obj._setMouseEvent event
        obj.mouseWheel.dispatch event
        false

      obj["_onMouseClick"] = (event) =>
        PXL.Context.switchContext obj
        obj._setMouseEvent event
        obj.mouseClick.dispatch event
        false

      obj.canvas.addEventListener "mousewheel",  obj["_onMouseWheel"], false
      obj.canvas.addEventListener "DOMMouseScroll", obj["_onDOMNouseScroll"], false

      obj.canvas.addEventListener "mouseclick", obj["_onMouseClick"], false
   
    else

      if obj.canvas.onmousewheel?
        obj["_onMouseWheel"] = (event) ->
          PXL.Context.switchContext obj
          obj._setMouseEvent event
          obj.mouseWheel.dispatch event
          false
        obj.canvas.onmousewheel = obj["_onMouseWheel"]

### removeMouseEmitter ###
removeMouseEmitter = (obj) ->
  if obj.canvas?
    #util.extend obj, MouseEmitter
    
    obj.canvas.removeEventListener('click', obj["_onMouseClick"])
    obj.canvas.removeEventListener('mousewheel', obj["_onMouseWheel"])
    obj.canvas.removeEventListener('DOMMouseScroll', obj["_onDOMNouseScroll"])
    obj.canvas.removeEventListener('mouseover', obj["_onMouseOver"])
    obj.canvas.removeEventListener('mouseout', obj["_onMouseOut"])
    obj.canvas.removeEventListener('mouseclick', obj["_onMouseClick"])
    obj.canvas.removeEventListener('mouseup', obj["_onMouseUp"])
    obj.canvas.removeEventListener('mousedown', obj["_onMouseDown"])
    obj.canvas.removeEventListener('mousemove', obj["_onMouseMove"])
    obj.canvas.removeEventListener('mousebutton', obj["_onMouseButton"])

    ###
    delete obj.mouseMove
    delete obj.mouseDown
    delete obj.mouseUp
    delete obj.mouseClick
    delete obj.mouseOut
    delete obj.mouseOver
    delete obj.mouseWheel
    ### 
    
  
module.exports = 
  makeMouseEmitter : makeMouseEmitter
  removeMouseEmitter : removeMouseEmitter
