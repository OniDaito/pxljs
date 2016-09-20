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

{Vec2, Vec3, Vec4, Matrix4} = require '../math/math'
{RGB, RGBA} = require '../colour/colour'
{PXLWarning} = require '../util/log'
{Curve2} = require '../math/curve'


### Interpolation ###
# A basic wrapper around a math / colour value that performs linear interpolation
# TODO - Quaternion's need to be here and probably just SLERPED

class Interpolation

  # **@constructor** - creates a new interpolation object
  # - **obj0** - an object of type Vec3, Vec3, RGB, RGBA, Quaternion or Number
  # - **obj1** - an object of type Vec3, Vec3, RGB, RGBA, Quaternion or Number 
  # - **curve** - a Curve
  constructor : (@obj0, @obj1, @curve) ->
  
    if not @curve?
      @curve = new Curve2()

    if typeof @obj0 == 'object' 
      if @obj0.__proto__  != @obj1.__proto__
        PXLWarning "Interpolating two different objects"
        
    # could replace this with simply interpolating all dictionary values that are numbers?
    if @obj0 instanceof Vec2
      @_set = @_setVec2

    else if @obj0 instanceof Vec3
      @_set = @_setVec3

    else if @obj0 instanceof Vec4
      @_set = @_setVec4

    else if @obj0 instanceof RGB
      @_set = @_setRGB

    else if @obj0 instanceof RGBA
      @_set = @_setRGBA

    else if @obj0 instanceof Quaternion
      @_set = @_setQuat

    else if typeof @obj0 == 'number'
      @_set = @_setScalar

    @_value = 0

  # **set** - set the value of this object
  # - **val** - a Number - 0 to 1 range
  # - returns a new Object of the same type as obj0 passed into the constructor
  set : (val) ->
    if val < 0 or val > 1.0
      PXLWarning("Interpolation set val must be between 0 and 1. It was set to " + val)
    @_value = val

    @_set()

  _setVec2 : () ->
    new Vec2(@obj0.x + ((@obj.x - @obj0.x) * @_value), @obj0.y + ((@obj1.y - @obj0.y) * @_value))

  _setVec3 : () ->
    new Vec3(@obj0.x + ((@obj1.x - @obj0.x) * @_value), 
        @obj0.y + ((@obj1.y - @obj0.y) * @_value),
        @obj0.z + ((@obj1.z - @obj0.z) * @_value)
    )

  _setVec4 : () ->
    new Vec4(@obj0.x + ((@obj1.x - @obj0.x) * @_value), 
        @obj0.y + ((@obj1.y - @obj0.y) * @_value),
        @obj0.z + ((@obj1.z - @obj0.z) * @_value),
        @obj0.w + ((@obj1.w - @obj0.w) * @_value)
    )

   _setRGB : () ->
    new RGB(@obj0.r + ((@obj1.r - @obj0.r) * @_value), 
        @obj0.g + ((@obj1.g - @obj0.g) * @_value),
        @obj0.b + ((@obj1.b - @obj0.b) * @_value)
    )

  _setRGBA : () ->
    new RGBA(@obj0.r + ((@obj1.r - @obj0.r) * @_value), 
        @obj0.g + ((@obj1.g - @obj0.g) * @_value),
        @obj0.b + ((@obj1.b - @obj0.b) * @_value),
        @obj0.a + ((@obj1.a - @obj0.a) * @_value)
    )

  # for a quaternion, we default to slerping
  _setQuat : () ->
    @obj0.slerp @obj1, @_value 

  _setScalar : () ->
    @obj0 + ((@obj1 - @obj0) * @_value)

## Animator ###
# A class that deals with animation. Essentially runs a series of frames at a particular framerate, with start / stop options
# TODO - Lots of testing of copyFrom - we might need to improve on that as its only numbers that violate that rule?
#
class Animator

  # **@constructor**
  # - **num_frames** - a Number
  # - **framerate** - a Number
  # - **label** - a String

  constructor : (@num_frames, @framerate, @label) ->

    if not @framerate?
      @framerate = 24
    
    if not @label?
      @label = "unlabled_animaton"

    @_current_frame = 0
    @_dt = 0
    @_loop = true
    @_frover = 1.0 / @framerate
    @_tweens = []

  # **addTween** - Add a tween to this keyframe
  # - **tween** - a Tween
  # - returns this
  addTween : (tween) ->
    @_tweens.push tween
    @

  # **reset** - set the animation back to the start position
  # - returns this 
  reset : () ->
    @_dt = 0
    @_current_frame = 0
    for tween in @_tweens
      tween.reset()
    @

  # **step** - Call step inside your draw function or similar, passing in dt - time time difference in seconds
  # - **dt** - a Number
  # - returns this
  step : (dt) ->

    @_dt += dt
 
    if @_dt >= @_frover

      # dt can be over the next frame by more than half a frame amount so we should think about this
      ff = Math.floor @_dt / @_frover
      @_current_frame += ff
      if @_current_frame >= @num_frames
        if @_loop
          reset()
        
      @_process()
      @_dt = @_dt - (ff * @_frover)
    @

  # Internal function that processes the values proper
  # We step through each tween and check where we are at with it
  _process : () ->
    for tween in @_tweens
      if tween.f0.framenum <= @_current_frame and tween.f1.framenum >= @_current_frame
        p = Math.abs(@_current_frame - tween.f0.framenum) /  Math.abs(tween.f0.framenum - tween.f1.framenum )
        tween.set p


### KeyFrame ###
# A reference to an object and the value that object should take at that point.
# Add keyframes to animators with the appropriate values
#
# TODO - should we pass in seconds or frames here?

class KeyFrame
  # **@constructor**
  # - **obj** - an Object
  # - **value** - a Value obj should take
  # - **framenum** - the framenumber at which point this object should take this value
  constructor : (@obj, @value, @framenum) ->
    @

### Tween ###
# A simple class that basically takes two keyframes and uses an interpolator to move between said values

class Tween
  # **@constructor** 
  # - **f0** - a KeyFrame
  # - **f1** - a KeyFrame
  # - **interp** - an Interpolation
  constructor : (@f0, @f1, @interp) ->
    
    if @f0.obj != @f1.obj
      PXLWarning "Tween Keyframes do not point to the same object"

    if not @interp?
      @interp = new Interpolation @f0.value, @f1.value

    if @f0.obj.copy?
      @_original = @f0.obj.clone()
      @reset = () ->
        @f0.copy @_original
    else
      @_original = @f0
      @reset = () ->
        @f0 = @_original
    @

  # **set**
  # - **u** - a Number - 0 to 1 range
  set: (u) ->
    if @f0.obj.copy?
      @f0.obj.copy @interp.set(u)
    else
      @f0.obj = @interp.set(u)

module.exports =
  Interpolation : Interpolation
  KeyFrame : KeyFrame
  Animator : Animator
  Tween : Tween
