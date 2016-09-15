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


- TODO
  * Combine mouse and touch cameras into one I think (possibly move to interact?)
  * Interactive cameras, when created should add listeners automagically to either window
    or some passed in DOM object I suspect. Saves us writing boilerplate code

  * Decouple the GL so we can test - but keep option in because its clean when used
  * TEST ORTHO CAMERA! I dont think it works! ><
  * update isnt really that great :S Keep it internal :)
  * functions to change the positions so we can change things like look pos and
    have the up vector change accordingly

https://gist.github.com/eligrey/384583 - useful for changes to pos,look etc?

###

{Vec2, Vec3,Vec4,Matrix4, Quaternion, degToRad} = require '../math/math'
{Primitive} = require '../geometry/primitive'
{makeMouseListener} = require '../interact/mouse'
{Contract} = require '../gl/contract'

### Camera ###
# The base class for cameras - provides base functionality to the other cameras

class Camera

  # **@constructor**
  # - **pos** - a Vec3
  # - **look** - a Vec3
  # - **up** - a Vec3
  constructor: (@pos, @look, @up) ->
    if not @pos?
      @pos = new Vec3 0,0,5
    if not @look?
      @look = new Vec3 0,0,0
    if not @up?
      @up = new Vec3 0,1,0

    # SHOULD call update here and figure out what up needs to be 
    # if we've not been given it :S

    @m = new Matrix4()
    @p = new Matrix4()
    @i = new Matrix4()
    @ip = new Matrix4()
    @q = new Quaternion() # Spare Quaternion to work out rotations
  
    # We keep these for the viewport calculations
    @width = 1
    @height = 1

    @contract = new Contract()
    @contract.roles.uCameraNear = "near"
    @contract.roles.uCameraFar  = "far"
    @contract.roles.uInverseProjectionMatrix  = "ip"
    @contract.roles.uProjectionMatrix         = "p"
    @contract.roles.uCameraMatrix             = "m"
    @contract.roles.uCameraInverseMatrix      = "i"


  # **update** - call this in your update function to update the matrices
  # TODO - I wonder if such things should be automatic on our draw / update 
  # paths through the nodes? Needs GL context ideally
  # - **width** - a Number - default current context width
  # - **height** - a Number - default current context height
  # - returns this

  update: (width=PXL.Context.width, height=PXL.Context.height) ->
    @m.lookAt @pos, @look, @up
    @i = Matrix4.invert(@m)
    
    @width = width
    @height = height

    GL.viewport 0, 0, @width, @height if GL?
    @


  # **lookat** - point the camera
  # - **pos** - a Vec3
  # - **look** - a Vec3
  # - **up** - a Vec3
  # - returns this
  lookAt : (@pos, @look, @up) ->
    @update()

  # **setViewport**
  # - **width** - a Number
  # - **height** - a Number
  # - returns this
  setViewport: (@width, @height) ->
    @
    
  # **orbit** -Rotate the camera around its look point.
  # - **axis** - a Vec3 - Required
  # - **angle** - a Number - Required - Radians
  # - returns this
  orbit : (axis, angle) ->
    @q.fromAxisAngle axis, angle
         
    dir = Vec3.sub @look, @pos
    dir.normalize()
    
    l = Vec3.sub @pos, @look

    @q.transVec3 l
    @q.transVec3 @up
    
    l.add @look

    @pos.copy l

    @update()
    @

  # **pantilt** - Pan and tilt the camera with an axis and angle notation
  # - **axis** - a Vec3 - Required
  # - **angle** - a Number - Required - Radians
  # - returns this
  pantilt : (axis, angle) ->

    @q.fromAxisAngle axis, angle
         
    dir = Vec3.sub @look, @pos
    dir.normalize()
      
    q2 = new Quaternion()

    q2.fromAxisAngle Vec3.cross(dir,@up), angle
    q2.mult @q

    q2.transVec3 @look
    q2.transVec3 @up
    
    @update()
    @


  # _addToNode - a function called when this class is added to a node
  _addToNode : (node) ->
    node.camera = @
    @

  # **track** - track the camera - v is a vec2 perpendicular to the look/pos dir
  # - **v** - a Vec2 - Required
  # - returns this
  track : (v) ->
    g = new Vec4 v.x,v.y,0,0 # non-homogenous vector w = 0
    @i.multVec g
        
    @look.add g
    @pos.add g
    @


### OrthoCamera ###
# An orthographic camera. This class calls makeOrtho on its perspective matrix
# Orthographic Camera uses 1 pixel as 1 world unit

class OrthoCamera extends Camera

  # **@constructor**
  # - **pos** - a Vec3 - Required
  # - **look** - a Vec3 - Required
  # - **up** - a Vec3 - Required
  # - **near** - a Number
  # - **far** - a Number
  constructor: (@pos, @look, @up, @near, @far) ->
    super(@pos,@look,@up)
    if not @near?
      @near = -1.0
    if not @far?
      @far = 1.0

  # update - call with width and height and the matrix will be updated
  # - **width** - a Number - Default is current context width
  # - **height** - a Number - Default is current context height
  # - returns this
  update: (width=PXL.Context.width, height=PXL.Context.height)->

    OrthoCamera.__super__.update.call(@, width, height)
    @p.makeOrtho(0, width, 0, height, @near, @far)
    @ip = Matrix4.invert(@p)

    @
    

### PerspCamera ###
# An perspective camera. This class calls makePerspective on its perspective matrix
# TODO - Not sure we need zoom here. Should probably have a spaceball class

class PerspCamera extends Camera

  # **@constructor** 
  # - **pos** - a Vec3 - Required
  # - **look** - a Vec3 - Required
  # - **up** - a Vec3 - Required
  # - **angle** - a Number
  # - **near** - a Number
  # - **far** - a Number
  constructor: (@pos, @look, @up, @angle, @near, @far) ->
    super(@pos,@look,@up)
    if not @angle?
      @angle = PXL.Math.degToRad 25.0
    if not @near?
      @near = 0.1
    if not @far?
      @far = 100.0

    @zoom_near = @near
    @zoom_far = @far

  # update - call with width and height and the matrix will be updated
  # - **width** - a Number - Default is current context width
  # - **height** - a Number - Default is current context height
  # - returns this
  update: (width=PXL.Context.width, height=PXL.Context.height)->
  
    PerspCamera.__super__.update.call(@, width, height)
    @p.makePerspective(@angle, width / height, @near, @far )
    @ip = Matrix4.invert(@p)
  
    @

  # **castRay** - Given a screen position (in pixels 0 -> dimension), cast a ray through the screen along the frustum from the eye pos
  # - **sx** - a Number - Required - Range 0 to width
  # - **sy** - a Number - Required - Range 0 to width
  # - **width** - a Number - Default is current context width
  # - **height** - a Number - Default is current context height
  # - returns a Vec4 - Normalised  

  castRay : (sx,sy, width=PXL.Context.width, height=PXL.Context.height) ->
  
    sy = height - sy
    
    near_ray = new Vec4((sx * 2.0)/ width - 1.0, (sy * 2) / height - 1, -1.0, 1.0)
    far_ray = new Vec4((sx * 2.0)/ width - 1.0, (sy * 2) / height - 1, 1.0, 1.0)

    @ip.multVec near_ray
    @ip.multVec far_ray

    nearg = 1.0 / near_ray.w
    near_ray_w = new Vec4 near_ray.x * nearg, near_ray.y * nearg, near_ray.z * nearg, 1.0

    farg = 1.0 / far_ray.w
    far_ray_w = new Vec4 far_ray.x * farg, far_ray.y * farg, far_ray.z * farg, 1.0

    far_ray_w.sub near_ray_w

    far_ray_w.normalize()

    @i.multVec far_ray_w
    far_ray_w.normalize()

  # change the zoom as a function of the current percentage of the distance between the near
  # and far clipping planes plus an offset percentage given by dt. Percentages are 0-1
  _zoom : (dt) ->

    dir = Vec3.sub(@look,@pos)
    dl = dir.length()
    
    tl = @zoom_far - @zoom_near
    dp = dl/tl
  
    @zoom dp+dt

    @

  # **zoom** - set the absolute zoom value between 0 and 1 - a percentage of the distance between
  # the near and far clip planes (by default - these can be changed)
  # - **z** - a Number - Required - Range 0 to 1
  # - returns this
  zoom : (z) ->
  
    if z >0 and z < 1
      dir = Vec3.sub(@pos,@look)
      dir.normalize()
      tl = @zoom_far - @zoom_near
      dir.multScalar(z * tl)
      @pos = Vec3.add(@look,dir)
      @update()

    @


### MousePerspCamera ###
# Camera that listens for mouse input and moves when the user moves the mouse around

class MousePerspCamera extends PerspCamera
  
  # **@constructor**
  # - **pos** - a Vec3 - Required
  # - **look** - a Vec3 - Required
  # - **up** - a Vec3 - Required
  # - **angle** - a Number
  # - **near** - a Number
  # - **far** - a Number
  # - **sense** - a Number
  
  constructor: ( @pos, @look, @up, @angle, @near, @far, @sense) ->
    super(@pos, @look, @up, @angle, @near, @far)
    
    # Listen for the signals on the PXL Context, emitting mouse events
    PXL.Context.mouseMove.add @onMouseMove, @
    PXL.Context.mouseDown.add @onMouseDown, @ 
    PXL.Context.mouseUp.add @onMouseUp, @
    PXL.Context.mouseWheel.add @onMouseWheel, @

    if not @sense?
      @sense = 0.3

    @px = 0
    @py = 0
    @dx = 0
    @dy = 0

    # This holds all we need to know about the camera
    @m.lookAt(@pos,@look,@up)
    @i = Matrix4.invert(@m)
    @

  # **onMouseMove** - registered with our signal - called when mouse is moved over canvas
  # - **event** - an Event
  # - returns this
  onMouseMove : (event)->

    x = event.mouseX
    y = event.mouseY
    
    @dx = x - @px 
    @px = x

    @dy = y - @py
    @py = y

    if event.buttonLeft
      @orbit new Vec3(0,1,0), degToRad(-@dx * @sense)
      dir = Vec3.sub @look, @pos
      @orbit Vec3.cross(dir,@up), degToRad(@dy * @sense)

    else if event.buttonRight
      @track new Vec2 @dx * @sense * -0.02, @dy * @sense * 0.02
      
    @
  
  # **onMouseDown** - registered with our signal - called when mouse button is pressed over canvas
  # - **event** - an Event
  # - returns this
  onMouseDown : (event) ->

    x = event.mouseX
    y = event.mouseY
    @px = x
    @py = y
    @dx = 0
    @dy = 0
    @

 
  # **onMouseUp** - registered with our signal - called when mouse button is released over canvas
  # - **event** - an Event
  # - returns this
  onMouseUp : (event) ->
    @

  # **onMouseWheel** - registered with our signal - called when mouse wheel is moved over canvas
  # At the moment, this appears to be chrome only
  # - **event** - an Event
  # - returns this
  onMouseWheel : (event) ->

    dt = event.wheelDelta * 0.01 * @sense
    tl = @far - @near

    dp = dt / tl
    @_zoom(dp)
    @

  # **update** - call with width and height and the matrix will be updated
  # - **width** - a Number - Default is current context width
  # - **height** - a Number - Default is current context height
  # - returns this
  update: (width=PXL.Context.width, height=PXL.Context.height)->
    MousePerspCamera.__super__.update.call(@, width, height)
    @
  
  # onMouseOut - registered with our signal - called when mouse leaves the context
  # - **event** - an Event
  # - returns this
  onMouseOut : (event) ->
    @px = 0
    @py = 0
    @dx = 0
    @dy = 0
    @

  # **onMouseOver** - registered with our signal - called when mouse enters the context
  # - **event** - an Event
  # - returns this 
  onMouseOver : (event) ->
    if @px == 0 and @py == 0
      [@px, @py] = [event.mouseX, event.mouseY]
    @

### TouchPerspCamera###
# Camera that listens for both mouse input and touch gestures

class TouchPerspCamera extends MousePerspCamera
  
  # **@constructor**
  # - **pos** - a Vec3 - Required
  # - **look** - a Vec3 - Required
  # - **up** - a Vec3 - Required
  # - **angle** - a Number
  # - **near** - a Number
  # - **far** - a Number
  # - **sense** - a Number
 
  constructor: ( @pos, @look, @up, @angle, @near, @far, @sense) ->
    super(@pos, @look, @up, @angle, @near, @far)
    
    # Listen for the signals on the PXL Context, emitting touch events
    PXL.Context.touchPinch.add @onPinch, @
    PXL.Context.touchSpread.add @onSpread, @
    PXL.Context.touchSwipe.add @onSwipe, @

  # **onPinch**
  # - **event** - an Event
  # - returns this 
  onPinch : (event) ->

    dt = -event.ddist * 0.08 * @sense
    tl = @far - @near
  
    dp = dt / tl
    @_zoom(dp)

    @

  # **onSpread**
  # - **event** - an Event
  # - returns this 
  onSpread : (event) ->
    
    dt = -event.ddist * 0.08 * @sense
    tl = @far - @near
  
    dp = dt / tl
    @_zoom(dp)

    @

  # **onSwipe**
  # - **event** - an Event
  # - returns this  
  onSwipe : (event) ->
    x = event.currentPos.x
    y = event.currentPos.y

    @px = event.previousPos.x
    @py = event.previousPos.y
      
    @dx = x - @px 
    @px = x

    @dy = y - @py
    @py = y

    if event.fingers == 1

      @orbit new Vec3(0,1,0), degToRad(-@dx * @sense)
      dir = Vec3.sub @look, @pos
      @orbit Vec3.cross(dir,@up), degToRad(-@dy * @sense)
        
    else if event.fingers == 2
      @track new Vec2 @dx * @sense * -0.02, @dy * @sense * 0.02
    @

module.exports = 
    Camera: Camera
    OrthoCamera: OrthoCamera
    PerspCamera: PerspCamera
    MousePerspCamera : MousePerspCamera
    TouchPerspCamera : TouchPerspCamera
