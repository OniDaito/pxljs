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


http://www.flipcode.com/documents/matrfaq.html
http://www.euclideanspace.com/maths/algebra/realNormedAlgebra/quaternions/index.htm

  - Thanks: Tojiro - https://github.com/toji/gl-matrix
  - Thanks: Cinder for most of the math!

The maths functons in PXLJS work as follows;
  - Any instance method that doesn't return a different tyoe to the instance, modifies 
    that instance and returns a reference to the original. For example:
    Vec3 a(1,0,0); 
    b = a.add(1,0,0);

    b will be a pointer or reference to a which will now have the value (2,0,0)

  - Class methods do the opposite to the above - they return a new version
    Vec3 a(1,0,0)
    Vec3 b(2,0,0)
    c = Vec3.add(a,b)
    
    c is now a new vector in its own right, with value (3,0,0)
  
  - Functions that are exceptions to this are things like dot, equals and length which
  return values that are not copies or references to thing being called upon.


- TODO
  * Matrix mult function for vectors as well as scalars and matrices
  * Some aliases (like multiply) might be nice
  * Make functions that multiply other things destructive
  * We have set/getPos on the matrices but should we have rotation as well?
  * multiply / divide as well that check the types for eloquence

###


{PXLWarning} = require '../util/log'

if typeof Float32Array?
  glMatrixArrayType = Float32Array
else if typeof WebGLFloatArray?
  glMatrixArrayType = WebGLFloatArray
else
  glMatrixArrayType = Array

# Useful constants
EPSILON = 4.37114e-05
PI = 3.14159

sinx_over_x : (x) ->
  if x * x < 1.19209290e-07
    return 1
  else
    return Math.sin(x) / x

radToDeg = (a) ->
  a * 57.2957795

degToRad = (a) ->
  a * 0.017453292523928


###Vec2###
# A two component vector with x,y

class Vec2

  DIM : 2

  # @sub - static function - non destructive subtraction.
  @sub:(a,b) ->
    a.copy()["sub"](b)

  # @add - static function - non destructive addition.
  @add:(a,b) ->
    a.copy()["add"](b)

  # @div - static function - non destructive division.
  @div:(a,b) ->
    a.copy()["div"](b)

  # @mult - static function - non destructive multiplication.
  @mult:(a,b) ->
    a.copy()["mult"](b)

  # @multScalar - static function - non destructive multiplication by a scalar
  @multScalar:(a,b) ->
    a.copy()["multScalar"](b)

  # @normalize - static function - non destructive normalization.
  @normalize:(a) ->
    a.copy()["normalize"]()

  # @dot - static function - return the dot product.
  @dot:(a,b) ->
    a.dot(b)

  constructor: (x=0,y=0) ->
  	[@x,@y] = [x,y]

  # copy - make a copy of this vector
  copy: ->
    new Vec2(@x,@y)

  # copyFrom - copy the value from another vector
  copyFrom : (a) ->
    @x = a.x
    @y = a.y
    @

  # length - return the length of this vector
  length: ->
    Math.sqrt @lengthSquared() 
  
  # lengthSquared - return the squared length of this vector
  lengthSquared: ->
    @x * @x + @y * @y

  # normalize - normalize - destructive
  normalize: ->
    m = @length()
    @multScalar(1.0/m) if m > 0
    @

  # sub - subtract another vector - destructive
  sub: (v) ->
    @x -= v.x
    @y -= v.y
    @

  # add - add another vector - destructive
  add: (v) ->
    @x += v.x
    @y += v.y
    @

  # dv - return a new vector being the difference between this vector and another (v)
  dv: (v) ->
    new Vec2  Math.abs(@x - v.x) Math.abs(@y - v.y) 

  # dist - return the distance between this and another vector (v)
  dist: (v) ->
    Vec2.sub(@,v).length()

  # distSquared - return the distance squared between this and another vector (v)
  distSquared: (v) ->
    Vec2.sub(@,v).lengthSquared()

  # div - divide by another vector n 
  div: (n) ->
    [@x,@y] = [@x/n.x,@y/n.y]
    @

  # mult - multiply by another vector v 
  mult: (v) ->
    [@x,@y] = [@x*v.x,@y*v.y]
    @

  # multScalar - multiply by a scalar n
  multScalar: (n) ->
    [@x,@y] = [@x*n,@y*n]
    @

  # equals - are these two vectors equal in size/direction
  equals: (v) ->
    @x == v.x and @y == v.y

  # dot - return the dot porduct between this and v
  dot: (v) ->
    @x*v.x + @y*v.y


  # invalid - is this vector actually valid
  invalid: ->
    return (@x == Infinity) || isNaN(@x) || @y == Infinity || isNaN(@y)

  # flatten - used by shaders to get a nice list
  flatten: ->
    [@x,@y]

  # Short-hand to set the values in one go
  set : (@x, @y) ->
    @


###Edge2###
# A container for two vertices, ordered as start and finish - directed

class Edge2

  constructor: (@start, @end) ->
    @
    
  # Convert this edge to a line in the form ax + by + c = 0
  equation : () ->
    [@start.y - @end.y, @end.x - @start.x, @start.x*@end.y - @end.x*@start.y]
    # TODO - Hold these for speed?

  sample : (x) ->
    [a,b,c] = @equation()
    (-a*x-c) / b

  length : () ->
    @end.dist @start


### HalfEdge2 ###
# An edge structure that points to the two faces it is connected to
# start / end are vertices and @face0, @face1 are either triangles
# or quads at present

# TODO - the relationship between math things and primitives is getting blurred. We need to 
# sort that out.

class HalfEdge2 extends Edge2
  constructor : (@start, @end, @face0, @face1) ->
    super(@start, @end)
    @


###Vec3###
# A 3 dimension vector (x,y,z)

class Vec3

  DIM : 3

  # @sub - static function - non destructive subtraction.
  @sub:(a,b) ->
    a.copy()["sub"](b)

  # @add - static function - non destructive addition.
  @add:(a,b) ->
    a.copy()["add"](b)

  # @cross - static function - return the cross product.
  @cross:(a,b) ->
    a.copy()["cross"](b)

  # @div - static function - non destructive division.
  @div:(a,b) ->
    a.copy()["div"](b)

  # @mult - static function - non destructive multiplication.
  @mult:(a,b) ->
    a.copy()["mult"](b)

  # @multScalar - static function - non destructive multiplication by a scalar
  @multScalar:(a,b) ->
    a.copy()["multScalar"](b)

  # @normalize - static function - non destructive normalization.
  @normalize:(a) ->
    a.copy()["normalize"]()

  # @dot - static function - return the dot product.
  @dot:(a,b) ->
    a.dot(b)
      
  constructor: (x=0,y=0,z=0) ->
  	[@x,@y,@z] = [x,y,z]

  # copy - make a copy of this vector
  copy: ->
    new Vec3(@x,@y,@z)

  # copyFrom - copy the value from another vector
  copyFrom : (a) ->
    @x = a.x
    @y = a.y
    @z = a.z
    @

  # xy - a basic swizzle returning a new Vec2
  xy : () ->
    new Vec3 @x, @y

  # length - return the length of this vector
  length: ->
    Math.sqrt @lengthSquared()  
  
  # lengthSquared - return the squared length of this vector
  lengthSquared: ->
    @x * @x + @y * @y + @z * @z

  # normalize - normalize - destructive
  normalize: ->
    m = @length()
    @multScalar(1.0/m) if m > 0
    @

  # sub - subtract another vector - destructive
  sub: (v) ->
    @x -= v.x
    @y -= v.y
    @z -= v.z
    @

  # add - add another vector - destructive
  add: (v) ->
    @x += v.x
    @y += v.y
    @z += v.z
    @

  # cross - cross this vector with another vector - destructive
  cross: (v) ->
    x = @y * v.z - @z * v.y 
    y = @z * v.x - @x * v.z 
    z = @x * v.y - @y * v.x
    @x = x
    @y = y
    @z = z
    @

  # dv - return a new vector being the difference between this vector and another (v)
  dv: (v) ->
    new Vec3  Math.abs(@x - v.x) Math.abs(@y - v.y) Math.abs(@z - v.z) 

  # dist - return the distance between this and another vector (v)
  dist: (v) ->
    Vec3.sub(@,v).length()

  # distSquared - return the distance squared between this and another vector (v)
  distSquared: (v) ->
    Vec3.sub(@,v).lengthSquared()

  # div - divide by another vector n 
  div: (n) ->
    [@x,@y,@z] = [@x/n.x,@y/n.y,@z/n.z]
    @

  # mult - multiply by another vector v 
  mult: (v) ->
    [@x,@y,@z] = [@x*v.x,@y*v.y,@z*v.z]
    @

  # multScalar - multiply by a scalar n
  multScalar: (n) ->
    [@x,@y,@z] = [@x*n,@y*n,@z*n]
    @

  # equals - are these two vectors equal in size/direction
  equals: (v) ->
    @x == v.x and @y == v.y and @z == v.z

  # dot - return the dot porduct between this and v
  dot: (v) ->
    @x*v.x + @y*v.y + @z*v.z

  # invalid - is this vector actually valid
  invalid: ->
    return (@x == Infinity) || isNaN(@x) || @y == Infinity || isNaN(@y) || @z == Infinity || isNaN(@z)

  # flatten - used by shaders to get a nice list
  flatten: ->
    [@x,@y,@z]


  # Short-hand to set the values in one go
  set : (@x, @y, @z) ->
    @

###Vec4###
# A four dimensional vector (x,y,z,w)

class Vec4

  DIM : 4
 
  # @sub - static function - non destructive subtraction.
  @sub:(a,b) ->
    a.copy()["sub"](b)

  # @add - static function - non destructive addition.
  @add:(a,b) ->
    a.copy()["add"](b)

  # @cross - static function - return the cross product.
  @cross:(a,b) ->
    a.copy()["cross"](b)

  # @div - static function - non destructive division.
  @div:(a,b) ->
    a.copy()["div"](b)

  # @mult - static function - non destructive multiplication.
  @mult:(a,b) ->
    a.copy()["mult"](b)

  # @multScalar - static function - non destructive multiplication by a scalar
  @multScalar:(a,b) ->
    a.copy()["multScalar"](b)

  # @normalize - static function - non destructive normalization.
  @normalize:(a) ->
    a.copy()["normalize"]()

  # @dot - static function - return the dot product.
  @dot:(a,b) ->
    a.dot(b)

  constructor: (x=0,y=0,z=0,w=1) ->
  	[@x,@y,@z,@w] = [x,y,z,w]

  # copy - make a copy of this vector
  copy: ->
    new Vec4(@x,@y,@z,@w)

  # copyFrom - copy the value from another vector
  copyFrom : (a) ->
    @x = a.x
    @y = a.y
    @z = a.z
    @w = a.w
    @

  # xyz - a basic swizzle returning a new Vec3
  xyz : () ->
    new Vec3 @x, @y, @z


  # length - return the length of this vector
  length: ->
    Math.sqrt @lengthSquared() 
  
  # lengthSquared - return the squared length of this vector
  lengthSquared: ->
    @x * @x + @y * @y + @z * @z + @w * @w

  # normalize - normalize - destructive
  normalize: ->
    m = @length()
    @multScalar(1.0/m) if m > 0
    @


  # sub - subtract another vector - destructive
  sub: (v) ->
    @x -= v.x
    @y -= v.y
    @z -= v.z
    @w -= v.w
    @

  # equals - are these two vectors equal in size/direction
  equals: (v) ->
    @x == v.x && @y == v.y && @z == v.z && @w == v.w

  # add - add another vector - destructive
  add: (v) ->
    @x += v.x
    @y += v.y
    @z += v.z
    @w += v.w
    @

  # cross - cross this vector with another vector - destructive
  cross: (v) ->
    # No idea what to do with W here! :S
    x = @y * v.z - @z * v.y 
    y = @z * v.x - @x * v.z 
    z = @x * v.y - @y * v.x
    @x = x
    @y = y
    @z = z
    @

  # dv - return a new vector being the difference between this vector and another (v)
  dv: (v) ->
    new Vec4  Math.abs(@x - v.x) Math.abs(@y - v.y) Math.abs(@z - v.z) Math.abs(@w - v.w) 

  # dist - return the distance between this and another vector (v)
  dist: (v) ->
    Vec4.sub(@,v).length()

  # distSquared - return the distance squared between this and another vector (v)
  distSquared: (v) ->
    Vec4.sub(@,v).lengthSquared()

  # div - divide by another vector n 
  div: (n) ->
    [@x,@y,@z,@w] = [@x/n.x,@y/n.y,@z/n.z,@w/n.w]
    @

  # mult - multiply by another vector v 
  mult: (v) ->
    [@x,@y,@z,@w] = [@x*v.x,@y*v.y,@z*v.z,@w*v.w]
    @ 

  # multScalar - multiply by a scalar n
  multScalar: (n) ->
    [@x,@y,@z,@w] = [@x*n,@y*n,@z*n,@w*n]
    @

  # dot - return the dot porduct between this and v
  dot: (v) ->
    @x*v.x + @y*v.y + @z*v.z + @w*v.w

  # invalid - is this vector actually valid
  invalid: ->
    return (@x == Infinity) || isNaN(@x) || @y == Infinity || isNaN(@y) || @z == Infinity || isNaN(@z) || @w == Infinity || isNaN(@w)

  # flatten - used by shaders to get a nice list
  flatten: ->
    [@x,@y,@z,@w]

  # Short-hand to set the values in one go
  set : (@x, @y, @z, @w) ->
    @

###Matrix2###
# A 2x2 matrix in Column Major Format

class Matrix2

  DIM : 2

  # @addScalar - static function - add a scalar to every element in this matrix
  @addScalar:(a,b) ->
    a.copy()["addScalar"](b)

  # @subScalar - static function - subtract a scalar from every element in this matrix
  @subScalar:(a,b) ->
    a.copy()["subScalar"](b)

  # @multScalar - static function - multiply every element in this matrix by a scalar
  @multScalar:(a,b) ->
    a.copy()["multScalar"](b)

  # @divScalar - static function - divide every element in this matrix by a scalar
  @divScalar:(a,b) ->
    a.copy()["divScalar"](b)

  # @mult - static function - multiply this matrix by another matrix
  @mult:(a,b) ->
    a.copy()["mult"](b)

  # @multVec - static function - multiply a vector by this matrix, returning a new vector
  @multVec: (m,v)->
    tv = v.copy()
    m.multVec(tv)
    tv

  # @transpose - static function - return the transpose of this matrix
  @transpose:(a) ->
    new Matrix2 [a.a[0],a.a[2],a.a[1],a.a[3]]

  # Take a list in column major format
  constructor: (a=[1,0,0,1]) ->
    if a instanceof Matrix2
      @a = a.a
    else
      @a = new glMatrixArrayType(a)

  # copy - return a copy of this matrix
  copy : () ->
    new Matrix2(@a)

  # copyFrom - copy all the values from another matrix, a
  copyFrom : (a) ->
    for i in [0..3]
      @a[i] = a.a[i]
    @

  # multScalar - multiply this matrix by a scalar
  multScalar: (n) ->
    @a = ( num * n for num in @a )
    @

  # addScalar - add a scalar to every element
  addScalar: (n) ->
    @a = ( num + n for num in @a )
    @

  # subScalar - remove a scalar from every element
  subScalar: (n) ->
    @a = ( num - n for num in @a )
    @

  # divScalar - divide every element by a scalar
  divScalar: (n) ->
    @a = ( num / n for num in @a)
    @

  # identity - set this matrix to be the identity matrix
  identity : ->
    @a.set([1,0,0,1])
    @
  
  # at - return the element at the row and column specified
  at : (r,c) ->
    @a[c * 2 + r]

  # mult - multiply this matrix by matrix m
  mult: (m) ->

    a = new Matrix2()

    a.a[ 0] = @a[ 0]*m.a[ 0] + @a[ 2]*m.a[ 1]
    a.a[ 1] = @a[ 1]*m.a[ 0] + @a[ 3]*m.a[ 1]
    a.a[ 2] = @a[ 0]*m.a[ 2] + @a[ 2]*m.a[ 3]
    a.a[ 3] = @a[ 1]*m.a[ 2] + @a[ 3]*m.a[ 3]
   
    @copyFrom(a)

    @

  # multVec - multiply vector v by this matrix - destructive to v
  multVec: (v) ->
    if v.z? or v.w?
      PXLWarning "Mismatched vector and matrix dimensions"
      return
    x = @a[ 0]*v.x + @a[ 2]*v.y
    y = @a[ 1]*v.x + @a[ 3]*v.y

    v.x = x
    v.y = y
    @

  # getCol - return a column from this matrix as a Vec2
  getCol: (c)->
    c = c * Matrix2.DIM
    Vec2 @a[c + 0] @a[c + 1]

  # getRow - return a row from this matrix as a Vec2
  getRow: (r) ->
    Vec2 @a[r + 0] @a[r + 2]

      

  # transpose - transpose this matrix
  transpose : () ->
    @copyFrom new Matrix2 [@a[0],a[2],@a[1],@a[3]]
    @

  # print - print this matrix to the console
  print: ()->
    console.log @a[0] + "," + @a[2]
    console.log @a[1] + "," + @a[3]
    
  
  # rotate - given an angle in radians, set this as a rotation matrix
  rotate: (a) ->

    r = new Matrix2()
    s = Math.sin a
    c = Math.cos a
   
    r.a[0] = c
    r.a[1] = s
    r.a[2] = -s
    r.a[3] = c

    @mult(r)
    @

  # scale - given a Vec3, create a scaling matrix
  scale: (v) ->
    # Leave w
    r = new Matrix3()
    r.a[0] = v.x
    r.a[4] = v.y
    r.a[8] = v.z
    @mult(r)
    @


###Matrix3###
# A 3x3 matrix in Column Major Format

class Matrix3

  DIM : 3
  # TODO - Euler x,y,z rotations needed? Probably not! :S

  # @addScalar - static function - add a scalar to every element in this matrix
  @addScalar:(a,b) ->
    a.copy()["addScalar"](b)

  # @subScalar - static function - subtract a scalar from every element in this matrix
  @subScalar:(a,b) ->
    a.copy()["subScalar"](b)

  # @multScalar - static function - multiply every element in this matrix by a scalar
  @multScalar:(a,b) ->
    a.copy()["multScalar"](b)

  # @divScalar - static function - divide every element in this matrix by a scalar
  @divScalar:(a,b) ->
    a.copy()["divScalar"](b)

  # @mult - static function - multiply this matrix by another matrix
  @mult:(a,b) ->
    a.copy()["mult"](b)

  # @invert - static function - return the inverse of this matrix
  @invert:(a) ->
    a["_invert"]()

  # @multVec - static function - multiply a vector by this matrix, returning a new vector
  @multVec: (m,v)->
    tv = v.copy()
    m.multVec(tv)
    tv

  # @transpose - static function - return the transpose of this matrix
  @transpose:(a) ->
    new Matrix3([ a.a.a.a[0],a.a[3],a.a[6],a.a[1],a.a[4],a.a[7],a.a[2],a.a[5],a.a[8]])


  # Take a list in column major format
  constructor: (a=[1.0,0.0,0.0,0.0,1.0,0.0,0.0,0.0,1.0]) ->
    if a instanceof Matrix3
      @a = a.a
    else
      @a = new glMatrixArrayType(a)

  # copy - return a copy of this matrix
  copy : () ->
    new Matrix3(@a)

  # copyFrom - copy all the values from another matrix, a
  copyFrom : (a) ->
    for i in [0..8]
      @a[i] = a.a[i]
    @

  # multScalar - multiply this matrix by a scalar
  multScalar: (n) ->
    @a = ( num * n for num in @a )
    @

  # addScalar - add a scalar to every element
  addScalar: (n) ->
    @a = ( num + n for num in @a )
    @

  # subScalar - remove a scalar from every element
  subScalar: (n) ->
    @a = ( num - n for num in @a )
    @

  # divScalar - divide every element by a scalar
  divScalar: (n) ->
    @a = ( num / n for num in @a)
    @

  # identity - set this matrix to be the identity matrix
  identity : ->
    @a.set([1.0,0.0,0.0,0.0,1.0,0.0,0.0,0.0,1.0])
    @
  
  # at - return the element at the row and column specified
  at : (r,c) ->
    @a[c * 3 + r]

  # mult - multiply this matrix by matrix m
  mult: (m) ->

    a = new Matrix3()

    a.a[ 0] = @a[ 0]*m.a[ 0] + @a[ 3]*m.a[ 1] + @a[ 6]*m.a[ 2]
    a.a[ 1] = @a[ 1]*m.a[ 0] + @a[ 4]*m.a[ 1] + @a[ 7]*m.a[ 2]
    a.a[ 2] = @a[ 2]*m.a[ 0] + @a[ 5]*m.a[ 1] + @a[ 8]*m.a[ 2]
   
    
    a.a[ 3] = @a[ 0]*m.a[ 3] + @a[ 3]*m.a[ 4] + @a[ 6]*m.a[ 5]
    a.a[ 4] = @a[ 1]*m.a[ 3] + @a[ 4]*m.a[ 4] + @a[ 7]*m.a[ 5]
    a.a[ 5] = @a[ 2]*m.a[ 3] + @a[ 5]*m.a[ 4] + @a[ 8]*m.a[ 5]
   
    
    a.a[ 6] = @a[ 0]*m.a[ 6] + @a[ 3]*m.a[ 7] + @a[ 6]*m.a[ 8]
    a.a[ 7] = @a[ 1]*m.a[ 6] + @a[ 4]*m.a[ 7] + @a[ 7]*m.a[ 8]
    a.a[ 8] = @a[ 2]*m.a[ 6] + @a[ 5]*m.a[ 7] + @a[ 8]*m.a[ 8]
   
    @copyFrom(a)

    @

  # multVec - multiply vector v by this matrix - destructive to v
  multVec: (v) ->
    if not v.z? or v.w?
      PXLWarning "Mismatched vector and matrix dimensions"
      return
    x = @a[ 0]*v.x + @a[ 3]*v.y + @a[ 6]*v.z
    y = @a[ 1]*v.x + @a[ 4]*v.y + @a[ 7]*v.z
    z = @a[ 2]*v.x + @a[ 5]*v.y + @a[ 8]*v.z

    v.x = x
    v.y = y
    v.z = z
    @

  # getCol - return a column from this matrix as a Vec3
  getCol: (c)->
    c = c * Matrix3.DIM
    Vec3 @a[c + 0] @a[c + 1] @a[c + 2]

  # getRow - return a row from this matrix as a Vec3
  getRow: (r) ->
    Vec3 @a[r + 0] @a[r + 3] @a[r + 6]

  # _invert - invert this matrix
  _invert: () ->
    inv = new Matrix3()
    epsilon = 4.37114e-05
    inv.a[0] = @a[4] * @a[8] - @a[5] * @a[7]
    inv.a[1] = @a[2] * @a[7] - @a[1] * @a[8]
    inv.a[2] = @a[1] * @a[5] - @a[2] * @a[4]
    inv.a[3] = @a[5] * @a[6] - @a[3] * @a[8]
    inv.a[4] = @a[0] * @a[8] - @a[2] * @a[6]
    inv.a[5] = @a[2] * @a[3] - @a[0] * @a[5]
    inv.a[6] = @a[3] * @a[7] - @a[4] * @a[6]
    inv.a[7] = @a[1] * @a[6] - @a[0] * @a[7]
    inv.a[8] = @a[0] * @a[4] - @a[1] * @a[3]

    det  = @a[0] * inv.a[0] + @a[1] * inv.a[3] + @a[2] * inv.a[6]

    if Math.abs(det) > epsilon
      invDet = 1.0 / det
      inv.multScalar(invDet)
    inv

  # invert - invert this matrix
  invert: () ->
    @copyFrom @_invert()
    @

 
  # transpose - transpose this matrix
  transpose : () ->
    @copyFrom new Matrix3([@a[0],@a[3],@a[6], @a[1],@a[4],@a[7], @a[2],@a[5],@a[8]])
    @

  # print - print this matrix to the console
  print: ()->
    console.log @a[0] + "," + @a[3] + "," + @a[6]
    console.log @a[1] + "," + @a[4] + "," + @a[7]
    console.log @a[2] + "," + @a[5] + "," + @a[8]
  
  # rotate - given a Vec3 and an angle in radians, create a rotation matrix
  rotate: (v,a) ->

    r = new Matrix3()
    s = Math.sin a
    c = Math.cos a
    v.normalize()

    r.a[0] = v.x * v.x * (1-c) + c
    r.a[1] = v.x * v.y * (1-c) + v.z * s
    r.a[2] = v.x * v.z * (1-c) - v.y * s
    
    r.a[3] = v.x * v.y * (1-c) - v.z * s
    r.a[4] = v.y * v.y * (1-c) + c
    r.a[5] = v.y * v.z * (1-c) + v.x * s

    r.a[6] = v.x * v.z * (1-c) + v.y * s
    r.a[7] = v.y * v.z * (1-c) - v.x * s
    r.a[8]= v.z * v.z * (1-c) + c

    @mult(r)
    @

  # scale - given a Vec3, create a scaling matrix
  scale: (v) ->
    # Leave w
    r = new Matrix3()
    r.a[0] = v.x
    r.a[4] = v.y
    r.a[8] = v.z
    @mult(r)
    @

###Matrix4###
# Our 4x4 matrix

class Matrix4
  DIM : 4

  # TODO - Euler x,y,z rotations needed? Probably not! :S

  # @addScalar - static function - adds a scalar to every element in the matrix
  @addScalar:(a,b) ->
    a.copy()["addScalar"](b)

  # @subScalar - static function - subtract a scalar from every element in this matrix
  @subScalar:(a,b) ->
    a.copy()["subScalar"](b)

  # @multScalar - static function - multiply every element in this matrix by a scalar
  @multScalar:(a,b) ->
    a.copy()["multScalar"](b)

  # @divScalar - static function - divide every element in this matrix by a scalar
  @divScalar:(a,b) ->
    a.copy()["divScalar"](b)

  # @mult - static function - multiply this matrix by another matrix
  @mult:(a,b) ->
    a.copy()["mult"](b)

  # @invert - static function - return the inverse of this matrix
  @invert:(a) ->
    a["_invert"]()

  # @transpose - static function - return the transpose of this matrix
  @transpose:(a) ->
    new Matrix4( [ a.a[0], a.a[4], a.a[8], a.a[12], a.a[1], a.a[5], a.a[9], a.a[13], a.a[2], a.a[6], a.a[10], a.a[14], a.a[3], a.a[7], a.a[11], a.a[15] ] )


  # @multVec - static function - multiply a vector by this matrix, returning a new vector
  @multVec: (m,v)->
    tv = v.copy()
    m.multVec(tv)
    tv



  # Take a list in column major format
  constructor: (a=[1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1]) ->
    # todo - add checking
    if a instanceof Matrix4
      @a = a.a
    else
      @a = new glMatrixArrayType(a)

  # copy - return a copy of this matrix
  copy : () ->
    new Matrix4(@a)

  # copyFrom - copy all the values from another matrix, a
  copyFrom : (a) ->
    for i in [0..15]
      @a[i] = a.a[i]
    @

  # multScalar - multiply this matrix by a scalar
  multScalar: (n) ->
    @a = ( num * n for num in @a )
    @

  # addScalar - add a scalar to every element
  addScalar: (n) ->
    @a = ( num + n for num in @a )
    @

  # subScalar - remove a scalar from every element
  subScalar: (n) ->
    @a = ( num - n for num in @a )
    @

  # divScalar - divide every element by a scalar
  divScalar: (n) ->
    @a = ( num / n for num in @a)
    @

  # identity - set this matrix to be the identity matrix
  identity : ->
    @a.set([1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1])
    @
  
  # at - return the element at the row and column specified
  at : (r,c) ->
    @a[c * 4 + r]

  # getMatrix3 - return the 3x3 matrix from this 4x4 - top left part
  getMatrix3 : () ->
    new Matrix3([ @a[0],@a[1],@a[2],@a[4],@a[5],@a[6],@a[8],@a[9],@a[10]])

  # mult - multiply this matrix by matrix m
  # TODO - I wonder if this is the fastest, best way? Probably not >< Not in place :S
  mult: (m) ->
    a = new Matrix4()
    a.a[ 0] = @a[ 0]*m.a[ 0] + @a[ 4]*m.a[ 1] + @a[ 8]*m.a[ 2] + @a[12]*m.a[ 3]
    a.a[ 1] = @a[ 1]*m.a[ 0] + @a[ 5]*m.a[ 1] + @a[ 9]*m.a[ 2] + @a[13]*m.a[ 3]
    a.a[ 2] = @a[ 2]*m.a[ 0] + @a[ 6]*m.a[ 1] + @a[10]*m.a[ 2] + @a[14]*m.a[ 3]
    a.a[ 3] = @a[ 3]*m.a[ 0] + @a[ 7]*m.a[ 1] + @a[11]*m.a[ 2] + @a[15]*m.a[ 3]
    
    a.a[ 4] = @a[ 0]*m.a[ 4] + @a[ 4]*m.a[ 5] + @a[ 8]*m.a[ 6] + @a[12]*m.a[ 7]
    a.a[ 5] = @a[ 1]*m.a[ 4] + @a[ 5]*m.a[ 5] + @a[ 9]*m.a[ 6] + @a[13]*m.a[ 7]
    a.a[ 6] = @a[ 2]*m.a[ 4] + @a[ 6]*m.a[ 5] + @a[10]*m.a[ 6] + @a[14]*m.a[ 7]
    a.a[ 7] = @a[ 3]*m.a[ 4] + @a[ 7]*m.a[ 5] + @a[11]*m.a[ 6] + @a[15]*m.a[ 7]
    
    a.a[ 8] = @a[ 0]*m.a[ 8] + @a[ 4]*m.a[ 9] + @a[ 8]*m.a[10] + @a[12]*m.a[11]
    a.a[ 9] = @a[ 1]*m.a[ 8] + @a[ 5]*m.a[ 9] + @a[ 9]*m.a[10] + @a[13]*m.a[11]
    a.a[10] = @a[ 2]*m.a[ 8] + @a[ 6]*m.a[ 9] + @a[10]*m.a[10] + @a[14]*m.a[11]
    a.a[11] = @a[ 3]*m.a[ 8] + @a[ 7]*m.a[ 9] + @a[11]*m.a[10] + @a[15]*m.a[11]
    
    a.a[12] = @a[ 0]*m.a[12] + @a[ 4]*m.a[13] + @a[ 8]*m.a[14] + @a[12]*m.a[15]
    a.a[13] = @a[ 1]*m.a[12] + @a[ 5]*m.a[13] + @a[ 9]*m.a[14] + @a[13]*m.a[15]
    a.a[14] = @a[ 2]*m.a[12] + @a[ 6]*m.a[13] + @a[10]*m.a[14] + @a[14]*m.a[15]
    a.a[15] = @a[ 3]*m.a[12] + @a[ 7]*m.a[13] + @a[11]*m.a[14] + @a[15]*m.a[15]

    @copyFrom(a)

    @

  # multVec - multiply vector v by this matrix - destructive to v
  multVec: (v) ->
    if not v.z?
      PXLWarning "Mismatched vector and matrix dimensions"
      return

    if not v.w?
      x = @a[ 0]*v.x + @a[ 4]*v.y + @a[ 8]*v.z + @a[12]
      y = @a[ 1]*v.x + @a[ 5]*v.y + @a[ 9]*v.z + @a[13]
      z = @a[ 2]*v.x + @a[ 6]*v.y + @a[10]*v.z + @a[14]
      w = @a[ 3]*v.x + @a[ 7]*v.y + @a[11]*v.z + @a[15] 
      v.x = x/w
      v.y = y/w
      v.z = z/w
    else
      x = @a[ 0]*v.x + @a[ 4]*v.y + @a[ 8]*v.z + @a[12] * v.w
      y = @a[ 1]*v.x + @a[ 5]*v.y + @a[ 9]*v.z + @a[13] * v.w
      z = @a[ 2]*v.x + @a[ 6]*v.y + @a[10]*v.z + @a[14] * v.w
      w = @a[ 3]*v.x + @a[ 7]*v.y + @a[11]*v.z + @a[15] * v.w
      v.x = x
      v.y = y
      v.z = z
      v.w = w
    @



  at: (r,c) ->
    @a[c * 4 + r]

  # getCol - return a column from this matrix as a Vec4
  getCol: (c)->
    c = c * 4
    Vec4 @a[c + 0] @a[c + 1] @a[c + 2] @a[c + 3]

  # getRow - return a row from this matrix as a Vec4
  getRow: (r) ->
    Vec4 @a[r + 0] @a[r + 4] @a[r + 8] @a[r + 12]

  # _invert - invert this matrix
  _invert : () ->

    inv = new Matrix4()
    epsilon = 4.37114e-05

    a0 = @a[ 0]*@a[ 5] - @a[ 1]*@a[4]
    a1 = @a[ 0]*@a[ 6] - @a[ 2]*@a[ 4]
    a2 = @a[ 0]*@a[ 7] - @a[ 3]*@a[ 4]
    a3 = @a[ 1]*@a[ 6] - @a[ 2]*@a[ 5]
    a4 = @a[ 1]*@a[ 7] - @a[ 3]*@a[ 5]
    a5 = @a[ 2]*@a[ 7] - @a[ 3]*@a[ 6]
    b0 = @a[ 8]*@a[13] - @a[ 9]*@a[12]
    b1 = @a[ 8]*@a[14] - @a[10]*@a[12]
    b2 = @a[ 8]*@a[15] - @a[11]*@a[12]
    b3 = @a[ 9]*@a[14] - @a[10]*@a[13]
    b4 = @a[ 9]*@a[15] - @a[11]*@a[13]
    b5 = @a[10]*@a[15] - @a[11]*@a[14]

    det = a0*b5 - a1*b4 + a2*b3 + a3*b2 - a4*b1 + a5*b0

    if  Math.abs( det ) > epsilon
      inv.a[ 0] = + @a[ 5]*b5 - @a[ 6]*b4 + @a[ 7]*b3
      inv.a[ 4] = - @a[ 4]*b5 + @a[ 6]*b2 - @a[ 7]*b1
      inv.a[ 8] = + @a[ 4]*b4 - @a[ 5]*b2 + @a[ 7]*b0
      inv.a[12] = - @a[ 4]*b3 + @a[ 5]*b1 - @a[ 6]*b0
      inv.a[ 1] = - @a[ 1]*b5 + @a[ 2]*b4 - @a[ 3]*b3
      inv.a[ 5] = + @a[ 0]*b5 - @a[ 2]*b2 + @a[ 3]*b1
      inv.a[ 9] = - @a[ 0]*b4 + @a[ 1]*b2 - @a[ 3]*b0
      inv.a[13] = + @a[ 0]*b3 - @a[ 1]*b1 + @a[ 2]*b0
      inv.a[ 2] = + @a[13]*a5 - @a[14]*a4 + @a[15]*a3
      inv.a[ 6] = - @a[12]*a5 + @a[14]*a2 - @a[15]*a1
      inv.a[10] = + @a[12]*a4 - @a[13]*a2 + @a[15]*a0
      inv.a[14] = - @a[12]*a3 + @a[13]*a1 - @a[14]*a0
      inv.a[ 3] = - @a[ 9]*a5 + @a[10]*a4 - @a[11]*a3
      inv.a[ 7] = + @a[ 8]*a5 - @a[10]*a2 + @a[11]*a1
      inv.a[11] = - @a[ 8]*a4 + @a[ 9]*a2 - @a[11]*a0
      inv.a[15] = + @a[ 8]*a3 - @a[ 9]*a1 + @a[10]*a0

    invDet = 1.0/det

    inv.multScalar(invDet)
    inv

  # invert - invert this matrix
  invert: () ->
    @copyFrom @_invert() 
    @

  # transpose - transpose this matrix
  transpose : () ->
    @copyFrom new Matrix4( [ @a[0],@a[4],@a[8],@a[12],@a[1],@a[5],@a[9],@a[13],@a[2],@a[6],@a[10],@a[14],@a[3],@a[7],@a[11],@a[15] ] )
    @


  # translate - multiple this matrix by a translation matrix, formed from the Vec3 v
  # TODO - Here is a good example of having a debug build as oppose to a debug flag!
  translate: (v) ->
    if v.DIM? 
      if v.DIM != 3
        PXLWarning "Mismatched vector and matrix dimensions"
        return @

    r = new Matrix4()
    r.a[12] = v.x
    r.a[13] = v.y
    r.a[14] = v.z
    @mult(r)
      
    @

  # setPos - Given a vector, sets the translation part of the matrix directly with no multiplication
  setPos : (v) ->
    @a[12] = v.x if v.x?
    @a[13] = v.y if v.y?
    @a[14] = v.z if v.z?
    @

  # getPos - return the translation component as a Vec3
  getPos : () ->
    return new Vec3 @a[12],@a[13],@a[14]
  
  # print - print this matrix to the console
  print: ()->
    console.log @a[0] + "," + @a[4] + "," + @a[8] + "," + @a[12]
    console.log @a[1] + "," + @a[5] + "," + @a[9] + "," + @a[13]
    console.log @a[2] + "," + @a[6] + "," + @a[10] + "," + @a[14]
    console.log @a[3] + "," + @a[7] + "," + @a[11] + "," + @a[15]


  # lookAt - similar to gluLookAt - creates a matrix from an eye, look and up vector (Vec3)
  lookAt: (eye,look,up) ->

    f = Vec3.sub(look,eye)
    f.normalize()
    u = up.copy()
    u.normalize()

    s = Vec3.cross(f,u)
    w = Vec3.cross(s,f)

    m = new Matrix4([s.x,u.x,-f.x,0,s.y,u.y,-f.y,0,s.z,u.z,-f.z,0,0,0,0,1])
    t = new Matrix4([1,0,0,0,0,1,0,0,0,0,1,0, -eye.x,-eye.y,-eye.z,1])

    m.mult(t)
    @copyFrom(m)
    @


  # makePerspective - given a field-of-view in degrees, an aspect ratio (w/h) and near and far clip planes
  # create a perspective matrix
  # TODO - Should we not use Radians here a we are using radians everywhere else?
  makePerspective: (fovy,aspect,znear,zfar) ->
    ymax = znear * Math.tan(fovy * Math.PI / 360.0)
    ymin = -ymax;
    xmin = ymin * aspect
    xmax = ymax * aspect
    @makeFrustum(xmin, xmax, ymin, ymax, znear, zfar)
    @

  # makeFrustum - used by makePerspective to create our frustrum 
  makeFrustum: (left, right,bottom, top, znear, zfar) ->
    x = 2*znear/(right-left)
    y = 2*znear/(top-bottom)
    a = (right+left)/(right-left)
    b = (top+bottom)/(top-bottom)
    c = -(zfar+znear)/(zfar-znear)
    d = -2*zfar*znear/(zfar-znear)
    @a = new glMatrixArrayType([x,0,0,0,0,y,0,0,a,b,c,-1,0,0,d,0])
    @

  # makeOrtho - given left,right,bottom,top, near and far floats, create an orthographic projection
  makeOrtho: (left, right, bottom, top, znear, zfar) ->
    tx = - (right + left) / (right - left)
    ty = - (top + bottom) / (top - bottom)
    tz = - (zfar + znear) / (zfar - znear)
    @a = new glMatrixArrayType([2 / (right - left),0,0,0,0, 2 / (top-bottom),0,0,0,0, -2 / (zfar - znear),0,tx,ty,tz,1])
    @

  # rotate - given a vector and an angle (radians), create the rotation part of this matrix
  rotate: (v,a) ->

    r = new Matrix4()
    s = Math.sin(a)
    c = Math.cos(a)
    v.normalize()

    r.a[0] = v.x * v.x * (1-c) + c
    r.a[1] = v.x * v.y * (1-c) + v.z * s
    r.a[2] = v.x * v.z * (1-c) - v.y * s
    
    r.a[4] = v.x * v.y * (1-c) - v.z * s
    r.a[5] = v.y * v.y * (1-c) + c
    r.a[6] = v.y * v.z * (1-c) + v.x * s

    r.a[8] = v.x * v.z * (1-c) + v.y * s
    r.a[9] = v.y * v.z * (1-c) - v.x * s
    r.a[10]= v.z * v.z * (1-c) + c
  
    @mult(r)
    @

  # scale - scale our matrix by a Vec3
  scale: (v) ->
    # Leave w
    r = new Matrix4()
    r.a[0] = v.x
    r.a[5] = v.y
    r.a[10] = v.z
    @mult(r)
    @


###Quaternion###
# A quaternion to deal with all our rotations

class Quaternion

  # @addScalar - static function - add a scalar to every element in this quaternion
  @addScalar:(a,b) ->
    a.copy()["addScalar"](b)

  # @subScalar - static function - subtract a scalar from every element in this quaternion
  @subScalar:(a,b) ->
    a.copy()["subScalar"](b)

  # @multScalar - static function - multiply every element in this quaternion by a scalar
  @multScalar:(a,b) ->
    a.copy()["multScalar"](b)

  # @divScalar - static function - divide every element in this quaternion by a scalar
  @divScalar:(a,b) ->
    a.copy()["divScalar"](b)

  # @conjugate - static function - return the conjugate to this quaternion
  @conjugate:(a) ->
    a.copy()["conjugate"]()

  # @mult - static function - multiply this quaternion by another quaternion
  @mult:(a,b) ->
    a.copy()["mult"](b)

  # @invert - static function - return an inverted version
  @invert:(a) ->
    a.copy()["invert"]()
 
  # transVec3 - static function - given a vector, return a new version of it, transformed by this quaternion
  @transVec3:(q,v) ->
    tv = v.copy()
    q.transVec3(tv)
    tv

  @fromRotations : (x,y,z) ->
    tv = new Quaternion()
    tv.fromRotations x,y,z
    tv

  # fromTo - static function - given two quaternions, return a new one from the first to the second
  @fromTo: (f,t) ->
    tv = new Quaternion()
    tv.fromTo(f,t)
    tv
  
  # constructor - takes a Vec3 and a w (both optional)
  constructor : (@x, @y, @z, @w) ->
    @x = 0 if not @x?
    @y = 0 if not @y?
    @z = 0 if not @z?
    @w = 1 if not @w?

  # copy - return a coy of this Quaternion
  copy : () ->
    new Quaternion @x, @y, @z, @w
 
  # copyFrom - copy another quaternion into this one
  copyFrom : (q) ->
    @x = q.x
    @y = q.y
    @z = q.z
    @w = q.w
    @

  # axis - return the axis of this Quaternion 
  axis : () ->
    ca = @w
    invlen = 1.0/ Math.sqrt(1.0 - ca * ca)
    @x *= invlen
    @y *= invlen
    @z *= invlen

  # angle - return the angle of this Quaternion
  angle : () ->
    ca = @w
    Math.acos(ca) * 2

  # pitch - return the pitch of this Quaternion
  pitch : () ->
    Math.atan2(2 * (@y * @z + @w * @x ), @w * @w - @x * @x - @y * @y + @z * @z )

  # yaw - return the pitch of this Quaternion
  yaw : () ->
    Math.sin(-2 * ( @x * @z - @w * @y ))

  # roll - return the pitch of this Quaternion
  roll: () ->
    Math.atan2(2 * ( @x * @y + @w * @z), @w * @w + @x * @x - @y * @y - @z * @z)

  # dot - return the dot product of this Quaternion with another
  dot : (a) ->
    @w * a.w + @x * a.x + @y * a.y + @z * a.z

  # length - return the length of this Quaternion
  length : () ->
    Math.sqrt @lengthSquared()
  
  # lengthSquared - return the lengthSquared of this Quaternion
  lengthSquared : () ->
    @w * @w + @x * @x + @y * @y + @z * @z


  # Conjugate
  conjugate : () ->
    @x = -@x
    @y = -@y
    @z = -@z
    @

  # invert - invert this quaternion
  invert : () ->
    q = Quaternion.conjugate(@)
    q = q.multScalar(1.0 / @lengthSquared())
    @x = q.x
    @y = q.y
    @z = q.z
    @w = q.w
    @

  # add - Add another quaternion to this one
  add : (q) ->
    @w += q.w
    @x += q.x
    @y += q.y
    @z += q.z
    @

  # sub - Subtract another quaternion from this one
  sub : (q) ->
    @w -= q.w
    @x -= q.x
    @y -= q.y
    @z -= q.z
    @

  # multiply - multiply this Quaternion with another
  multiply : (q) ->
    @mult(q)

  # mult - multiply this Quaternion with another
  mult: (q) ->
    w = -@x * q.x - @y * q.y - @z * q.z + @w * q.w
    x = @x * q.w + @y * q.z - @z * q.y + @w * q.x
    y = -@x * q.z + @y * q.w + @z * q.x + @w * q.y
    z = @x * q.y - @y * q.x + @z * q.w + @w * q.z
    @w = w
    @x = x 
    @y = y
    @z = z
    @

  # multScalar - multiply this Quaternion by a scalar
  multScalar : (s) ->
    @w *= s
    @x *= s
    @y *= s
    @z *= s
    @

  # transVec3 - Transform a vector by this quaternion

  # TODO - this appears to rotate a vector in the opposite direction to glm and other libs
  # We should check the maths on this one

  transVec3 : (v) ->
  
    qc = Quaternion.conjugate @
    vp = new Quaternion(v.x, v.y, v.z, 0)

    vf = qc.mult(vp).mult(@)
    v.x = vf.x
    v.y = vf.y
    v.z = vf.z

    @

  # normalize - normalize this quaternion
  normalize : () ->  
    len = 1.0 / @length()
    @w *= len
    @x *= len
    @y *= len      
    @z *= len
    @

  # log - ?
  log : () ->
    t = 1.0
    if @w < t
      t = @w
    
    theta = Math.acos(t)
    if theta == 0
      return new Quaternion(@x, @y, @z ,0)

    sintheta = Math.sin(theta)
    k = theta / sintheta
    if Math.abs(sintheta) < 1 and Math.abs(theta) >= 3.402823466e+38 * Math.abs(sintheta)
      k  =1

    new Quaternion @x*k, @y*k, @z*k, 0

  # exp - ?
  exp : () ->

    theta = @v.length()
    sintheta = sin(theta)
    k = sintheta / theta

    if Math.abs(theta) < 1 and Math.abs(sintheta) >= 3.402823466e+38 * Math.abs(theta)
      k  =1

    costheta = Math.cos(theta)
  
    new Quaternion @x * k, @y * k, @z * k, costheta

  # fromTo - set this quaternion to represent the movement from quaternion to another
  fromTo : (f,t) ->
    axis = Vec3.cross(f,t)
    @w = f.dot(t)
    @x = axis.x
    @y = axis.y
    @z = axis.z
    @normalize()
    @w += 1.0

    if @w <= EPSILON
      if f.z * f.z > f.x * f.x
        @w = 0.0
        @x = 0
        @y = f.z
        @z = -f.y
      else
        @w = 0.0
        @x = f.y
        @y = -f.x
        @z = 0.0
      @normalize()
    @

  # fromAxisAngle - create a quaternion that represents rotation around an axis (a) (Vec3) radians (r)
  fromAxisAngle : (a,r) ->
    @w = Math.cos(r / 2)
    v = new Vec3(a.x,a.y,a.z)
    v.normalize().multScalar(Math.sin(r/2))
    @x = v.x
    @y = v.y
    @z = v.z
    @

  # fromRotations - create a Quaternion from rotations around z,y,and x in that order in radians
  fromRotations : (x,y,z) ->
    x *= 0.5
    y *= 0.5
    z *= 0.5

    cx = Math.cos x
    sx = Math.sin x

    cy = Math.cos y
    sy = Math.sin y

    cz = Math.cos z
    sz = Math.sin z

    @w  = cx * cy * cz - sx * sy * sz
    @x = sx*cy*cx + cx*sy*sz
    @y = cx*sy*cz - sx*cy*sz
    @z = cx*cy*sz + sx*sy*cx
    @

  # getAxisAngle - return the axis and angle represented by this quaternion
  getAxisAngle : () ->
    ca = @w
    r = Math.acos(ca) * 2
    invlen = 1.0 / Math.sqrt(1.0 - ca * ca)

    [new Vec3(@x * invlen, @y * invlen, @z * invlen), r] 


  # getMatrix4 - return a matrix4 from this Quaternion
  getMatrix4 : () ->

    xs = @x + @x   
    ys = @y + @y
    zs = @z + @z
    wx = @w * xs
    wy = @w * ys
    wz = @w * zs
    xx = @x * xs
    xy = @x * ys
    xz = @x * zs
    yy = @y * ys
    yz = @y * zs
    zz = @z * zs

    new Matrix4( [1.0 - (yy+zz),
      xy + wz,
      xz - wy,
      0,
      xy - wz,
      1.0 - ( xx + zz ),
      yz + wx,
      0,
      xz + wy,
      yz - wx,
      1.0 - ( xx + yy ),
      0,
      0,
      0,
      0,
      1.0])

  # getMatrix3 - return a matrix3 from this Quaternion - The rotation component
  getMatrix3 : () ->

    xs = @x + @x   
    ys = @y + @y
    zs = @z + @z
    wx = @w * xs
    wy = @w * ys
    wz = @w * zs
    xx = @x * xs
    xy = @x * ys
    xz = @x * zs
    yy = @y * ys
    yz = @y * zs
    zz = @z * zs

    new Matrix3( [1.0 - (yy+zz),
      xy + wz,
      xz - wy,
      xy - wz,
      1.0 - ( xx + zz ),
      yz + wx,
      xz + wy,
      yz - wx,
      1.0 - ( xx + yy )])


  # lerp - lerp between this quaternion at the start and the one at the 'end', t being 0->1
  lerp : (t,end) ->
   
    costheta = end.dot()
    result = Quaternion.multScalar(end,t)
    if costheta >= EPSILON
      result.add (result.multScalar(1.0 - t)) 
    else
      result.add (result.multScalar(t - 1.0))
    result

  # slerpShortestUnenforced - slerp between this quaternion at the start and the one at the 'end', t being 0->1
  slerpShortestUnenforced : (t,end) ->
    d = @copy()
    d.sub(end)
    lengthD = Math.sqrt(@dot(end))
    st = @copy()
    st.add(end)
    lengthS = Math.sqrt(st.dot(st))

    a = 2 * Math.atan2(lengthD,lengthS)
    s = 1 - t

    q = @copy()
    q.multScalar(( sinx_over_x( s * a ) / sinx_over_x( a ) * s ) )
    e = end.copy()
    e.multScalar(( sinx_over_x( t * a ) / sinx_over_x( a ) * t ))
    q.add(e)
    q.normalize()
    q

  # slerp - slerp between this quaternion at the start and the one at the 'end', t being 0->1
  slerp : (t,end) ->
    cosTheta = @dot( end )

    if cosTheta >= EPSILON
      if  1.0  - cosTheta  > EPSILON
        theta = Math.acos(cosTheta)
        recipSinTheta = 1.0 / Math.sin(theta)
        startInterp = Math.sin( (1.0 - t) * theta) * recipSinTheta
        endInterp = Math.sin( t * theta) * recipSinTheta
      else
        startInterp = 1.0 - t
        endInterp = t
    else 
      if 1.0 + cosTheta > EPSILON
        theta = Math.acos(-cosTheta)
        recipSinTheta = 1.0 / Math.sin(theta)
        startInterp = Math.sin((t - 1.0) * theta ) * recipSinTheta
        endInterp = Math.sin(t*theta) * recipSinTheta       
      
      else
        startInterp = t -1.0
        endInterp = t
   
    q = @copy()
    q.mult(startInterp)
    e = end.copy()
    e.mult(endInterp)
    q.add(e)
    q 

  # fromMatrix4 : Create a Quaternion from an existing Matrix4
  fromMatrix4 : (m) ->

    trace = m.a[0] + m.a[5] + m.a[10]

    if  trace > 0.0
      s = Math.sqrt(trace + 1.0)
      @w = s * 0.5
      recip = 0.5 / s

      @x = ( m.at(2,1) - m.at(1,2) ) * recip
      @y = ( m.at(0,2) - m.at(2,0) ) * recip
      @z = ( m.at(1,0) - m.at(0,1) ) * recip

    else 
      i = 0
      if m.at(1,1) > m.at(0,0)
        i = 1
      if m.at(2,2) > m.at(i,i)
        i = 2

      j = ( i + 1 ) % 3
      k = ( j + 1 ) % 3
      s = Math.sqrt(m.at(i,i) - m.at(j,j) - m.at(k,k) + 1.0)

      if i == 0
        @x = 0.5 * s
      else if i == 1
        @y = 0.5 * s
      else 
        @z = 0.5 * s

      recip = 0.5 / s

      @w = ( m.at(k,j) - m.at(j,k) ) * recip

      a = ( m.at(j,i) + m.at(i,j) ) * recip
      b = ( m.at(k,i) + m.at(i,k) ) * recip

      if j == 0
        @x = a
      else if j == 1
        @y = a
      else 
        @z = a

      if k == 0
        @x = b
      else if k == 1
        @y = b
      else 
        @z = b

    @



module.exports = 
  Vec2 : Vec2
  Vec3 : Vec3
  Vec4 : Vec4
  Matrix2 : Matrix2
  Matrix3 : Matrix3
  Matrix4 : Matrix4
  radToDeg : radToDeg
  degToRad : degToRad
  Quaternion: Quaternion
  PI : PI
  EPSILON : EPSILON
  Edge2 : Edge2


