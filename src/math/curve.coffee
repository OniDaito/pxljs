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

{Vec2, Vec3, Vec4, Matrix4, PI } = require '../math/math'

### Curve2 ###
# The basis for a series of two dimensional curves. These may or may not be normalised
# This class also can be used to represent a straight line with gradient one, through
# the origin - basically your classic straight line

class Curve2

  # **@constructor**
  constructor : () ->
    @

  # **pointOnCurve** - Return the point on this curve given u (or x)
  # - **u** - a Number - Required
  # - returns a new Vec2
  pointOnCurve : (u) ->
    new Vec2 u,u

  # **y** - Given x give us y
  # - **x** - a Number - Required
  # - returns a Number
  y : (x) ->
    x

  # **stepForU** - given U return the step distance 
  # - **x** - Step along the curve x o
  # - returns a Number
  stepForU : (x) ->
    x
  
  # **xForStep** - given d step along the curve give us x
  # - **d** - a Number
  # - returns a Number
  xForStep : (d) ->
    x

  # **pointDistance** 
  # - **d** - a Number
  # - returns a new Vec2
  pointDistance : (d) ->
    # sqrt(d^2 / 2) = a
    t = Math.sqrt(d*d/2.0)
    new Vec2 t,t
 
  # **tangentOnCurve**
  # - **x** - a Number
  # - returns a new Vec2
  tangentOnCurve : (x) ->
    new Vec2 1,1

  # **tangentDistance**
  # - **d** - a Number
  # - returns a new Vec2
  tangentDistance: (d) ->
    new Vec2 1,1

### Curve ###
# The basis for any parametric curve. We cache values for distance and u so we can
# step along the curve using distance or normalized values
# TODO - Rename this as CurveP - for parametric

class Curve

  # Our step size along the curve to generate points
  @step_rez = 0.01

  # Cache points for speed as oppose to memory
  # TODO - Might change to instance variables later
  @cache_table = true 
  @cache_size = 200

  # **@constructor**
  constructor : () ->

    @length = 0

    if Curve.cache_table
      # create a table of positions as a cache
      @_table = []
      step = 1 / Curve.cache_size
      for i in [0..Curve.cache_size-1]
        tu = i * step
        @_table.push { u : tu, d : @stepForU(tu) }
      @length = @_table[ @_table.length - 1]["d"]

    else
      @length = @stepForU(1.0)

    @

  # **pointOnCurve** - Return the point on this curve given u (or x)
  # - **u** - a Number - Required
  # - returns a new Vec3
  pointOnCurve : (u) ->
    new Vec3 0,0,0

  # **stepForU** - given U return the step distance 
  # - **x** - Step along the curve x o
  # - returns a Number
  stepForU : (u) ->

    if u == 0
      return 0

    prev_dist = 0
    curr_dist = 0
    prev_u = 0
    curr_u = 0
    prev_point = @pointOnCurve(0)
    curr_point = prev_point

    while curr_u < u
      prev_dist = curr_dist
      prev_u = curr_u
      prev_point.copyFrom curr_point

      curr_u += Curve.step_rez
      curr_point = @pointOnCurve curr_u
      curr_dist += curr_point.dist prev_point
      
    du = (u - prev_u) / (curr_u - prev_u)

    du * (curr_dist - prev_dist) + prev_dist 

   
  # **uForStep** - given a euclidean distance what is the step
  # - **d** - a Number
  # - returns a new Vec3
  uForStep : (d) ->

    if d == 0
      return 0

    prev_dist = 0
    curr_dist = 0
    prev_u = 0
    curr_u = 0
    prev_point = @pointOnCurve(0)
    curr_point = prev_point

    while curr_dist < d
      prev_dist = curr_dist
      prev_u = curr_u
      prev_point.copyFrom curr_point

      curr_u += Curve.step_rez
      curr_point = @pointOnCurve curr_u
      curr_dist += curr_point.dist prev_point


    dd = d - prev_dist
    if (curr_dist - prev_dist) > 0    
      dd = dd / (curr_dist - prev_dist)

    dd * (curr_u - prev_u) + prev_u 

  # **pointDistance**
  # - **d** - a Number - Required
  # - returns a new Vec3
  pointDistance : (d) ->
    # If we have a cache table step through it and find u

    if d == 0
      return @pointOnCurve 0

    if d >= @length
      return @pointOnCurve 1.0

    if @_table
      curr_dist = 0
      curr_u = 0
      prev_dist = 0
      prev_u = 0

      for step in @_table
       
        prev_u = curr_u
        prev_dist = curr_dist

        curr_u = step.u
        curr_dist = step.d 

        if step.d >= d
          break

      dd = d - prev_dist
      if (curr_dist - prev_dist) > 0    
        dd = dd / (curr_dist - prev_dist)

      @pointOnCurve( dd * (curr_u - prev_u) + prev_u )

    else 
      @pointOnCurve @uForStep d

  # **tangentOnCurve** - get a tangent from the normalised co-ordinate
  # - **u** - a Number - Required
  # - returns a new Vec3
  tangentOnCurve : (u) ->
    v0 = @pointOnCurve(u) 
    v1 = @pointOnCurve(u + Curve.step_rez / 2)
    
    if u >= 1.0
      v1 = v0
      v0 = v1 - Curve.step_rez / 2

    Vec3.sub(v1,v0).normalize()

  # **tangentDistance ** - get a tangent from the distance along the curve
  # - **d** - a Number
  # - returns a new Vec3
  tangentDistance : (d) ->
    v0 = @pointDistance(d) 
    v1 = @pointDistance(d + Curve.step_rez / 2)
    
    if d >= @length
      v1 = v0
      v0 = v1 - Curve.step_rez / 2

    Vec3.sub(v1,v0).normalize()


### BezierCubic3 ###
# A Quadratic, bezier curve with four vectors determining the shape
# A 3D curve as oppose to 2D

class BezierCubic3 extends Curve

  # **@constructor**
  # - **v0** - a Vec3 - Required
  # - **v1** - a Vec3 - Required
  # - **v2** - a Vec3 - Required
  # - **v3** - a Vec3 - Required
  constructor : (@v0,@v1,@v2,@v3) ->
    super()

  _B1 : (t) ->
    t*t*t
  
  _B2 : (t) ->
    3*t*t*(1-t)
  
  _B3 : (t) ->
    3*t*(1-t)*(1-t)

  _B4 : (t) -> 
    (1-t)*(1-t)*(1-t)

  # **pointOnCurve** 
  # - **u** - a Number - Range 0 to 1 - Required
  # - returns a new Vec3
  pointOnCurve: (u) ->
    new Vec3( v0.x*@_B1(u) + v1.x*@_B2(u) + v2.x*@_B3(u) + v3.x*@_B4(u),
      v0.y*@_B1(u) + v1.y*@_B2(u) + v2.y*@_B3(u) + v3.y*@_B4(u),
      v0.z*@_B1(u) + v1.z*@_B2(u) + v2.z*@_B3(u) + v3.z*@_B4(u))
  

# TODO This formula actually works IF you remmeber there are two answers
# It DOESNT work for lines that are parallel to the x or y axis
# We need to revert to the directrix equation for that - this happens
# if either a or b is 0
# Takes the line in the form ax + by + c = 0
# This is nothing to do with the song "Parabola" by the band Tool; at least
# I don't think it is :S
# @f - The Focus as a Vec2
# @a - parameter of the line equation (or 0 if x directrix)
# @b - parameter of the line equation (or 0 if y directrix)
# @c - parameter of the line equation

class Parabola 
  # **constructor**
  # - **f** - a Vec2 - Required
  # - **a** - a Number - Required
  # - **b** - a Number - Required
  # - **c** - a Number - Required
  constructor : (@f, @a, @b, @c) ->
    @

  # **sample**
  # - **x** - a Number - Required
  # - returns an Array of Number - Length 2
  sample : (x) ->

    # Three ways to sample - arbitrary line, x axis or y axis
    if @a == 0 and @b != 0
      # x axis aligned
      # (x-h)^2 = 4p(y-k)
      h = @f.x
      k = (@f.y + @c) / 2
      p = @f.y - k

      a = 1/(4*p)
      b = -h/(2*p)
      c = (h*h)/(4*p) + k
      y = a*x*x+b*x+c
      return [y,y]

    else if @b == 0 and @a != 0
      # y axis aligned - use the quadratic formula as we will have two answers
      
      h = (@f.x + @c) / 2
      k = @f.y
      p = @f.x - h

      y0 = Math.sqrt(4*p*(x-h)) + k
      y1 = k - Math.sqrt(4*p*(x-h))
        
      return [y0,y1]
   
    else if @a != 0  and @b != 0
      as = @a * @a
      bs = @b * @b
      cs = @c * @c
      u = @f.x
      us = u * u
      v = @f.y
      vs = v * v
      xs = x * x
      t0 = (-2*as*v-2*@a*@b*x-2*bs*v-2*@b*@c)

      t1 = Math.sqrt((t0*t0)-4*as*(as*us-2*as*u*x+as*vs-2*@a*@c*x+bs*us-2*bs*u*x+bs*vs+bs*xs-cs))
      t2 = 2*as*v+2*@a*@b*x+2*bs*v+2*@b*@c
      t3 = 2*as

      [ (-t1 + t2) / t3, (t1 + t2) / t3 ]
    else
      PXLError("Malformed ")
      return [0,0]

  # **lineCrossing** - figure out where a line crosses this parabola given the equation in the form ax + by + c = 0
  # - **e** - a Number - Required
  # - **f** - a Number - Required
  # - **g** - a Number - Required
  lineCrossing : (e,f,g) ->

    #[e,f,g] = line.equation()
    
    # TODO - line crossing for edges that are parallel to a major axis!
    a = @a
    b = @b
    c = @c
    as = @a * @a 
    bs = @b * @b
    cs = @c * @c
    fs = f * f
    es = e * e
    gs = g * g
    h = @f.x
    k = @f.y
    hs = h * h
    ks = k * k

    console.log a,b,c,f,e,g,h,k

    t0 = (2*as*e*f*k+2*as*e*g-2*as*fs*h+2*a*b*f*g-2*a*c*fs+2*bs*e*f*k-2*bs*fs*h+2*b*c*e*f)
    console.log "t0",t0
    t1 = 4*(as*es+2*a*b*e*f+bs*fs)*(as*fs*hs+as*fs*ks+2*as*f*g*k+as*gs+bs*fs*hs+bs*fs*ks+2*bs*f*g*k+2*b*c*f*g-cs*fs)
    console.log "t1",t1
    t2 = 2*as*e*f*k-2*as*e*g+2*as*fs*h-2*a*b*f*g+2*a*c*fs-2*bs*e*f*k+2*bs*fs*h-2*b*c*e*f
    console.log "t2",t2
    t3 = 2*(as*es+2*a*b*e*f+bs*fs)
    console.log "t3",t3


    x0 = (-Math.sqrt(t0*t0-t1)-t2)/t3
    x1 = (Math.sqrt(t0*t0-t1)-t2)/t3
    
    [ new Vec2(x0, (-e*x0-g)/f), new Vec2(x1, (-e*x1-g)/f) ]


### CatmullPatch ###
#

class CatmullPatch 
  # TODO - as we are are not keeping a count of the points, we cant really
  # alter the patch on the fly :( 

  # **@constructor**
  # - **points** - an Array of Vec3 - Length 16 - Required
  # Assume points are given in column major order!
  constructor : (points) ->
    
    if points.length != 16
      PXLError "Catmull Patch needs 16 points"
      return

    b = new Matrix4([-0.5,1,-0.5,0,1.5,-2.5,0,1,-1.5,2,0.5,0,0.5,-0.5,0,0])

    # Create the matrices we need for the output points
    t = []
    for p in points
      t.push p.x
    @px = new Matrix4(t)

    t = []
    for p in points
      t.push p.y
    @py = new Matrix4(t)

    t = []
    for p in points
      t.push p.z
    @pz = new Matrix4(t)

    bt = Matrix4.transpose(b)

    @px = Matrix4.mult(b,@px).mult(bt)
    @py = Matrix4.mult(b,@py).mult(bt)
    @pz = Matrix4.mult(b,@pz).mult(bt)


  # **sample** - Sample the patch with a vec2 (u,w) to gain the required point 
  # - **v** - a Vec2 - Required
  # - returns a new Vec3
  sample : (v) ->
    u1 = v.x
    u2 = u1 * u1
    u3 = u2 * u1

    w1 = v.y
    w2 = w1 * w1
    w3 = w2 * w1
    
    u = new Vec4(u3,u2,u1,1)
    w = new Vec4(w3,w2,w1,1)

    um = Matrix4.multVec(@px, w)
    x = u.x * um.x + u.y * um.y + u.z * um.z + u.w * um.w

    um = Matrix4.multVec(@py, w)
    y = u.x * um.x + u.y * um.y + u.z * um.z + u.w * um.w

    um = Matrix4.multVec(@pz, w)
    z = u.x * um.x + u.y * um.y + u.z * um.z + u.w * um.w

    new Vec3(x,y,z)

  # TODO - eventually use the proper matrix http://www.cubic.org/docs/hermite.htm

### CubicHermiteSpline ###
class CubicHermiteSpline extends Curve

  # **@constructor**
  # - **p0** - a Vec3 - Required
  # - **p1** - a Vec3 - Required
  # - **m0** - a Vec3 - Required
  # - **m1** - a Vec3 - Required
  constructor : (@p0, @p1, @m0, @m1) ->
    super()
    @

  # **pointOnCurve** - Return the point on this curve given u (or x)
  # - **u** - a Number - Required
  # - returns a new Vec3 
  pointOnCurve : (u) ->

    t3 = u*u*u 
    t2 = u*u

    c0 = @p0.copy().multScalar(2 * t3 - 3 * t2 + 1) 
    c1 = @m0.copy().multScalar(t3 - 2 * t2 + u)
    c2 = @p1.copy().multScalar(-2 * t3 + 3 * t2)
    c3 = @m1.copy().multScalar(t3 - t2)

    c0.add(c1).add(c2).add(c3)

### CatmullRomSpline ###
# A collection of curves forming a Catmull-rom spline.

class CatmullRomSpline extends Curve

  # TODO - as we are are not keeping a count of the points, we cant really
  # alter the spline on the fly :(
  # **@constructor**
  # - **points** - an Array of Vec3 - Minimum Length 4 - Required
  constructor : (points) ->

    if points.length < 4
      PXLError "Catmull-Rom Spline needs at least 4 points"
      return

    # Build from a set of CubicHermiteSplines
    segments  = points.length - 3

    @splines = []
 
    for i in [0..segments-1]
      m0 = points[i+2].copy().sub( points[i])
      m1 = points[i+3].copy().sub( points[i+1])

      @splines.push new CubicHermiteSpline points[i+1], points[i+2], m0, m1

    super()
    @

  # **pointOnCurve** - Return the point on this curve given u (or x)
  # - **u** - a Number - Range 0 to 1 - Required
  # - returns a new Vec3
  pointOnCurve : (u) ->

    # Decide where in spline we are given the numbers we have
    segment  = Math.floor(u * @splines.length)

    if u >= 1
      @splines[@splines.length-1].pointOnCurve (1.0)
    else if u <= 0
      @splines[0].pointOnCurve(0)
    else
      @splines[segment].pointOnCurve ( (@splines.length * u) - segment)


### CurveSlide ###
# http://www.cs.cmu.edu/~fp/courses/graphics/asst5/cameraMovement.pdf
# essentially step along via a distance, passing in previous values
# and setting new ones

class CurveSlide 

  # **@constructor**
  # - **curve** - a Curve - Required
  # - **normal** - a Vec3 - Required
  constructor : (@curve, @normal) ->
    @reset @normal,0

  # **reset** - reset the slide starting from distance d, with a starting normal
  # - **normal** - a Vec3 - Required
  # - **d** - a Number - Default 0
  # - returns this
  reset : (@normal, d=0) ->
    @d = d
    @pos = @curve.pointDistance @d
    @tangent = @curve.tangentDistance @d
    @bp = Vec3.cross @normal, @tangent
    @np = @normal
    @binormal = @bp
    @

  # **slide** - slide along the curve from the starting point by d distance
  # - **dd** - a Number - Required
  # - returns this
  slide : (dd) ->
    @d += dd
    if @d > @curve.length
      @reset @normal, 0

    @pos = @curve.pointDistance @d
    @tangent = @curve.tangentDistance @d

    @bp = @binormal
 
    @normal = Vec3.cross @bp, @tangent
    @binormal = Vec3.cross @tangent, @normal
    @


### NURB ###
# NURB Class
# TODO - Most of it - there is still a fair bit to go

class NURB extends Curve
  constructor : () ->
    @

module.exports = 
  Curve2 : Curve2
  BezierCubic3:  BezierCubic3
  CubicHermiteSpline : CubicHermiteSpline
  CatmullRomSpline : CatmullRomSpline
  Parabola : Parabola
  CatmullPatch : CatmullPatch
  CurveSlide : CurveSlide
