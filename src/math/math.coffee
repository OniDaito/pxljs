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
###

# The maths functons in PXLjs work as follows;
# any instance function that doesnt return a different type to the instance, modifies 
# that instance and returns a reference to the original. For example:
#
#     Vec3 a(1,0,0); 
#     b = a.add(1,0,0);

#  b will be a pointer or reference to a which will now have the value (2,0,0)

# Class fucntions do the opposite to the above - they return a new version
#
#     Vec3 a(1,0,0)
#     Vec3 b(2,0,0)
#     c = Vec3.add(a,b)
    
#  c is now a new vector in its own right, with value (3,0,0)
  
# Functions that are exceptions to this are things like dot, equals and length which
# return values that are not copies or references to thing being called upon.


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


### Vec2 ###
# A two component vector with x,y

class Vec2

  DIM : 2

  # **@sub** - static function - non destructive subtraction.
  # - **a** - Vec2
  # - **b** - Vec2
  # - returns a new Vec2
  @sub:(a,b) ->
    a.clone()["sub"](b)

  # **@add** - static function - non destructive subtraction.
  # - **a** - Vec2
  # - **b** - Vec2
  # - returns a new Vec2
  @add:(a,b) ->
    a.clone()["add"](b)

  # **@div** - static function - non destructive division.
  # - **a** - Vec2
  # - **b** - Vec2
  # - returns a new Vec2
  @div:(a,b) ->
    a.clone()["div"](b)

  # **@mult** - static function - non destructive multiplication.
  # - **a** - Vec2
  # - **b** - Vec2
  # - returns a new Vec2
  @mult:(a,b) ->
    a.clone()["mult"](b)

  # **@multScalar** - static function - non destructive multiplication with a scalar.
  # - **a** - Vec2
  # - **b** - Number
  # - returns a new Vec2
  @multScalar:(a,b) ->
    a.clone()["multScalar"](b)

  # **@normalize** static function - non destructive normalization.
  # - **a** - Vec2
  # - returns a new Vec2
  @normalize:(a) ->
    a.clone()["normalize"]()

  # **@dot** - static function - compute the dot product
  #  - **a** - Vec2
  #  - **b** - Vec2
  #  - returns a Number
  @dot:(a,b) ->
    a.dot(b)

  # **@constructor** - Create a new Vec2
  # - **x** - Number
  # - **y** - Number
  # - returns a new Vec2
  constructor: (x=0,y=0) ->
  	[@x,@y] = [x,y]

  # **clone** - make a clone of this vector
  # - returns a new Vec2

  clone: ->
    new Vec2(@x,@y)

  # **copy** - copy the value from another vector
  # - **a** - Vec2
  # - returns this
  copy: (a) ->
    @x = a.x
    @y = a.y
    @

  # **length** - return the length of this vector
  # - returns a number
  length: ->
    Math.sqrt @lengthSquared() 
  
  # **lengthSquared** - return the squared length of this vector
  # - returns a number
  lengthSquared: ->
    @x * @x + @y * @y

  # **normalize** - normalize this vector
  # - returns this
  normalize: ->
    m = @length()
    @multScalar(1.0/m) if m > 0
    @

  # **sub** - subtract another vector from this one
  # - **v** - a Vec2
  # - returns this
  sub: (v) ->
    @x -= v.x
    @y -= v.y
    @

  # **add** - add another vector to this one
  # - **v** - a Vec2
  # - returns this
  add: (v) ->
    @x += v.x
    @y += v.y
    @

  # **dv** - return a new vector being the difference between this vector and another
  # - **v** - a Vec2
  # - returns a new Vec2
  dv: (v) ->
    new Vec2  Math.abs(@x - v.x) Math.abs(@y - v.y) 

  # **dist** - return the distance between this and another vector
  # - **v** - a Vec2
  # - returns a Number
  dist: (v) ->
    Vec2.sub(@,v).length()

  # **distSquared** - return the distance squared between this and another vector
  # - **v** - a Vec2
  # - returns a Number
  distSquared: (v) ->
    Vec2.sub(@,v).lengthSquared()

  # **div** - divide by another vector n
  # - **n** - a Vec2
  # - returns this
  div: (n) ->
    [@x,@y] = [@x/n.x,@y/n.y]
    @

  # **mult** - multiply by another vector v
  # - **v** - a Vec2
  # - returns this
  mult: (v) ->
    [@x,@y] = [@x*v.x,@y*v.y]
    @

  # **multScalar** - multiply by a scalar n
  # - **n** - a Vec2
  # - returns this
  multScalar: (n) ->
    [@x,@y] = [@x*n,@y*n]
    @

  # **equals** - are these two vectors equal in size/direction
  # - **v** a Vec2
  # - returns a boolean
  equals: (v) ->
    @x == v.x and @y == v.y

  # **dot** - return the dot product between this and v
  # - **v** a Vec2
  # - returns a Number
  dot: (v) ->
    @x*v.x + @y*v.y


  # **invalid** - is this vector actually valid
  # - returns a boolean
  invalid: ->
    return (@x == Infinity) || isNaN(@x) || @y == Infinity || isNaN(@y)

  # **flatten** - used by shaders to get a nice list
  # - returns a List of Number
  flatten: ->
    [@x,@y]

  # **set** - Short-hand to set the values in one go
  # - **x** - Number
  # - **y** - Number
  # - returns a Number
  set : (@x, @y) ->
    @


### Edge2 ###
# A container for two vertices, ordered as start and finish - directed

class Edge2

  # **constructor** 
  # - **start** - a Vec2
  # - **end** - a Vec2
  constructor: (@start, @end) ->
    @
    
  # **equation** - Convert this edge to a line in the form ax + by + c = 0
  # - returns a List of Number
  equation : () ->
    [@start.y - @end.y, @end.x - @start.x, @start.x*@end.y - @end.x*@start.y]

  # **sample** - point on the line given x
  # - **x** - Number
  # - returns a Number
  sample : (x) ->
    [a,b,c] = @equation()
    (-a*x-c) / b

  # **length** - return the length of this edge
  # - returns a Number
  length : () ->
    @end.dist @start


### HalfEdge2 ###
# **Incomplete**
# An edge structure that points to the two faces it is connected to
# start / end are vertices and @face0, @face1 are either triangles
# or quads at present


class HalfEdge2 extends Edge2

  constructor : (@start, @end, @face0, @face1) ->
    super(@start, @end)
    @


### Vec3 ###
# A 3 dimension vector (x,y,z)
class Vec3

  DIM : 3

  # **@sub** - static function - non destructive subtraction.
  # - **a** - a Vec3
  # - **b** - a Vec3
  # - returns a new Vec3
  @sub:(a,b) ->
    a.clone()["sub"](b)

  # **@add** - static function - non destructive addition.
  # - **a** - a Vec3
  # - **b** - a Vec3
  # - returns a new Vec3
  @add:(a,b) ->
    a.clone()["add"](b)

  # **@cross** - static function - return the cross product.
  # - **a** - a Vec3
  # - **b** - a Vec3
  # - returns a new Vec3
  @cross:(a,b) ->
    a.clone()["cross"](b)

  # **@div** - static function - non destructive division.
  # - **a** - a Vec3
  # - **b** - a Vec3
  # - returns a new Vec3
  @div:(a,b) ->
    a.clone()["div"](b)

  # **@mult** - static function - non destructive multiplication.
  # - **a** - a Vec3
  # - **b** - a Vec3
  # - returns a new Vec3
  @mult:(a,b) ->
    a.clone()["mult"](b)

  # **@perp** - static function - non destructive perpendicular.
  # - **a** - a Vec3
  # - returns a new Vec3
  @perp:(a) ->
    a.clone()["perp"]()

  # **@multScalar** - static function - non destructive multiplication by a scalar
  # - **a** - a Vec3
  # - **b** - a Vec3
  # - returns a Number
  @multScalar:(a,b) ->
    a.clone()["multScalar"](b)

  # **@normalize** - static function - non destructive normalization.
  @normalize:(a) ->
    a.clone()["normalize"]()

  # **@dot** - static function - return the dot product.
  # - **a** - a Vec3
  # - **b** - a Vec3
  # - returns a Number
  @dot:(a,b) ->
    a.dot(b)
      
  # **constructor**
  # - **x** - a Number
  # - **y** - a Number
  # - **z** - a Number
  # - returns a new Vec3
  constructor: (x=0,y=0,z=0) ->
  	[@x,@y,@z] = [x,y,z]

  # **clone** - make a clone of this vector
  # - returns a new Vec3
  clone: ->
    new Vec3(@x,@y,@z)

  # **copy** - copy the value from another vector
  # - **a** - a Vec3
  # - returns this
  copy: (a) ->
    @x = a.x
    @y = a.y
    @z = a.z
    @

  # **xy** - a basic swizzle returning a new Vec2 from x and y
  # - returns a Vec2
  xy : () ->
    new Vec3 @x, @y

  # **length** - return the length of this vector
  # - returns a Number
  length: ->
    Math.sqrt @lengthSquared()  
  
  # **lengthSquared** - return the squared length of this vector
  # - returns a Number
  lengthSquared: ->
    @x * @x + @y * @y + @z * @z

  # **normalize** - normalize - destructive
  # - returns a Number
  normalize: ->
    m = @length()
    @multScalar(1.0/m) if m > 0
    @

  # **sub** - subtract another vector - destructive
  # - **v** - a Vec3
  # - returns this
  sub: (v) ->
    @x -= v.x
    @y -= v.y
    @z -= v.z
    @

  # **add** - add another vector - destructive
  # - **v** - Vec3
  # - returns this
  add: (v) ->
    @x += v.x
    @y += v.y
    @z += v.z
    @

  # **cross** - cross this vector with another vector - destructive
  # - **v** - Vec3
  # - returns this
  cross: (v) ->
    x = @y * v.z - @z * v.y 
    y = @z * v.x - @x * v.z 
    z = @x * v.y - @y * v.x
    @x = x
    @y = y
    @z = z
    @

  # **dv** - return a new vector being the difference between this vector and another (v)
  # - **v** - Vec3
  # - returns this
  dv: (v) ->
    @x = Math.abs(@x - v.x)
    @y = Math.abs(@y - v.y)
    @z = Math.abs(@z - v.z)
    @

  # **dist** - return the distance between this and another vector (v)
  # - **v** - Vec3
  # - returns a Number
  dist: (v) ->
    Vec3.sub(@,v).length()

  # **distSquared** - return the distance squared between this and another vector (v)
  # - **v** - Vec3
  # - returns a Number
  distSquared: (v) ->
    Vec3.sub(@,v).lengthSquared()

  # **div** - divide by another vector n 
  # - **n** - Vec3
  # - returns this
  div: (n) ->
    [@x,@y,@z] = [@x/n.x,@y/n.y,@z/n.z]
    @

  # **perp** - set this vector to one perpendicular to itself 
  # - returns this
  perp : () ->
    if @z != 0
      @z = (-@x * 2.0 - @y) / @z
      @x = 2.0
      @y = 1.0
    else if @y != 0
      @y = (-@x * 2.0 - @z) / @y
      @x = 2.0
      @z = 1.0
    else if @x != 0
      @x = (-@y * 2.0 - @z) / @x
      @y = 2.0
      @z = 1.0

    @ 


  # **mult** - multiply by another vector v 
  # - **v** - Vec3
  # - returns this
  mult: (v) ->
    [@x,@y,@z] = [@x*v.x,@y*v.y,@z*v.z]
    @

  # **multScalar** - multiply by a scalar n
  # - **n** - Number
  # - returns this
  multScalar: (n) ->
    [@x,@y,@z] = [@x*n,@y*n,@z*n]
    @

  # **equals** - are these two vectors equal in size/direction
  # - **v** - Vec3
  # returns boolean
  equals: (v) ->
    @x == v.x and @y == v.y and @z == v.z

  # dot - return the dot product between this and v
  # - **v** - Vec3
  # - return this
  dot: (v) ->
    @x*v.x + @y*v.y + @z*v.z

  # **invalid** - is this vector actually valid
  # - returns boolean
  invalid: ->
    return (@x == Infinity) || isNaN(@x) || @y == Infinity || isNaN(@y) || @z == Infinity || isNaN(@z)

  # **flatten** - used by shaders to get a nice list
  # - returns List of Number
  flatten: ->
    [@x,@y,@z]

  # **set** - Short-hand to set the values in one go
  # - **x** - Number
  # - **y** - Number
  # - **z** - Number
  # - returns this
  set : (@x, @y, @z) ->
    @

### Vec4 ###
# A four dimensional vector (x,y,z,w)

class Vec4

  DIM : 4
 
  # **@sub** - static function - non destructive subtraction.
  # - **a** - Vec4
  # - **b** - Vec4
  # - returns new Vec4
  @sub:(a,b) ->
    a.clone()["sub"](b)

  # **@add** - static function - non destructive addition.
  # - **a** - Vec4
  # - **b** - Vec4
  # - returns new Vec4
  @add:(a,b) ->
    a.clone()["add"](b)

  # **@cross** - static function - return the cross product.
  # - **a** - Vec4
  # - **b** - Vec4
  # - returns new Vec4
  @cross:(a,b) ->
    a.clone()["cross"](b)

  # **@div** - static function - non destructive division.
  # - **a** - Vec4
  # - **b** - Vec4
  # - returns new Vec4
  @div:(a,b) ->
    a.clone()["div"](b)

  # **@mult** - static function - non destructive multiplication.
  # - **a** - Vec4
  # - **b** - Vec4
  # - returns new Vec4
  @mult:(a,b) ->
    a.clone()["mult"](b)

  # **@multScalar** - static function - non destructive multiplication by a scalar
  # - **a** - Vec4
  # - **b** - Number
  # - returns Number
  @multScalar:(a,b) ->
    a.clone()["multScalar"](b)

  # **@normalize** - static function - non destructive normalization.
  # - **a** - Vec4
  # - returns new Vec4
  @normalize:(a) ->
    a.clone()["normalize"]()

  # **@dot** - static function - return the dot product.
  # - **a** - Vec4
  # - **b** - Vec4
  # - returns Number
  @dot:(a,b) ->
    a.dot(b)

  # **constructor**
  # - **x** - Number - optional - default 0
  # - **y** - Number - optional - default 0
  # - **z** - Number - optional - default 0
  # - **w** - Number - optional - default 1
  constructor: (x=0,y=0,z=0,w=1) ->
  	[@x,@y,@z,@w] = [x,y,z,w]

  # **clone** - make a clone of this vector
  # - returns new Vec4
  clone: ->
    new Vec4(@x,@y,@z,@w)

  # **copy** - copy the value from another vector
  # - **a** - Vec4
  # - returns this
  copy: (a) ->
    @x = a.x
    @y = a.y
    @z = a.z
    @w = a.w
    @

  # **xyz** - a basic swizzle returning a new Vec3
  # - returns new Vec3
  xyz : () ->
    new Vec3 @x, @y, @z


  # **length** - return the length of this vector
  # - returns Number
  length: ->
    Math.sqrt @lengthSquared() 
  
  # **lengthSquared** - return the squared length of this vector
  # - returns Number
  lengthSquared: ->
    @x * @x + @y * @y + @z * @z + @w * @w

  # **normalize** - normalize - destructive
  # - returns this
  normalize: ->
    m = @length()
    @multScalar(1.0/m) if m > 0
    @


  # **sub** - subtract another vector - destructive
  # - **v** - Vec4
  # - returns this  
  sub: (v) ->
    @x -= v.x
    @y -= v.y
    @z -= v.z
    @w -= v.w
    @

  # **equals** - are these two vectors equal in size/direction
  # - **v** - Vec4
  # - returns boolean
  equals: (v) ->
    @x == v.x && @y == v.y && @z == v.z && @w == v.w

  # **add** - add another vector - destructive
  # - **v** - Vec4
  # - returns this
  add: (v) ->
    @x += v.x
    @y += v.y
    @z += v.z
    @w += v.w
    @

  # *cross* - cross this vector with another vector - destructive
  # - **v** - Vec4
  # - return this
  cross: (v) ->
    # No idea what to do with W here! :S
    x = @y * v.z - @z * v.y 
    y = @z * v.x - @x * v.z 
    z = @x * v.y - @y * v.x
    @x = x
    @y = y
    @z = z
    @

  # **dv** - set this vector to the difference between this vector and another (v)
  # - **v** - Vec4
  # - returns this
  dv: (v) ->
    @x = Math.abs(@x - v.x)
    @y = Math.abs(@y - v.y)
    @z = Math.abs(@z - v.z)
    @w = Math.abs(@w - v.w) 
    @


  # **dist** - return the distance between this and another vector (v)
  # - **v** - Vec4
  # - returns Number
  dist: (v) ->
    Vec4.sub(@,v).length()

  # **distSquared** - return the distance squared between this and another vector (v)
  # - **v** - Vec4
  # - returns Number
  distSquared: (v) ->
    Vec4.sub(@,v).lengthSquared()

  # **div** - divide by another vector n
  # - **n** - Vec4
  # - returns this 
  div: (n) ->
    [@x,@y,@z,@w] = [@x/n.x,@y/n.y,@z/n.z,@w/n.w]
    @

  # **mult** - multiply by another vector v 
  # - **v** - Vec4
  # - returns this
  mult: (v) ->
    [@x,@y,@z,@w] = [@x*v.x,@y*v.y,@z*v.z,@w*v.w]
    @ 

  # **multScalar** - multiply by a scalar n
  # - **n** - Number
  # - returns this
  multScalar: (n) ->
    [@x,@y,@z,@w] = [@x*n,@y*n,@z*n,@w*n]
    @

  # **dot** - return the dot porduct between this and v
  # - **v** - Vec4
  # - returns this
  dot: (v) ->
    @x*v.x + @y*v.y + @z*v.z + @w*v.w

  # **invalid** - is this vector actually valid
  # - returns boolean
  invalid: ->
    return (@x == Infinity) || isNaN(@x) || @y == Infinity || isNaN(@y) || @z == Infinity || isNaN(@z) || @w == Infinity || isNaN(@w)

  # **flatten** - used by shaders to get a nice list
  # - returns List of Number
  flatten: ->
    [@x,@y,@z,@w]

  # **set** - Short-hand to set the values in one go
  # - **x** - Number
  # - **y** - Number
  # - **z** - Number
  # - **w** - Number
  set : (@x, @y, @z, @w) ->
    @

### Matrix2 ###
# A 2x2 matrix in Column Major Format

class Matrix2

  DIM : 2

  # **@addScalar** - static function - add a scalar to every element in this matrix
  # - **a** - Matrix2
  # - **b** - Number
  # - returns new Matrix2
  @addScalar:(a,b) ->
    a.clone()["addScalar"](b)

  # **@subScalar** - static function - subtract a scalar from every element in this matrix
  # - **a** - Matrix2
  # - **b** - Number
  # - returns new Matrix2
  @subScalar:(a,b) ->
    a.clone()["subScalar"](b)

  # **@multScalar** - static function - multiply every element in this matrix by a scalar
  # - **a** - Matrix2
  # - **b** - Number
  # - returns new Matrix2
  @multScalar:(a,b) ->
    a.clone()["multScalar"](b)

  # **@divScalar** - static function - divide every element in this matrix by a scalar
  # - **a** - Matrix2
  # - **b** - Number
  # - returns new Matrix2
  @divScalar:(a,b) ->
    a.clone()["divScalar"](b)

  # **@mult** - static function - multiply this matrix by another matrix
  # - **a** - Matrix2
  # - **b** - Matrix2
  # - returns new Matrix2
  @mult:(a,b) ->
    a.clone()["mult"](b)

  # **@multVec** - static function - multiply a vector by this matrix, returning a new vector
  # - **m** - Matrix2
  # - **v** - Vec2
  # - returns new Vec2
  @multVec: (m,v)->
    tv = v.clone()
    m.multVec(tv)
    tv

  # **@transpose** - static function - return the transpose of this matrix
  # - **a** - Matrix2
  # - returns new Matrix2
  @transpose:(a) ->
    new Matrix2 [a.a[0],a.a[2],a.a[1],a.a[3]]

  # **constructor** Take a list in column major format
  # - **a** - List of Number - Length 4 - Optional - Default [1,0,0,1]
  constructor: (a=[1,0,0,1]) ->
    if a instanceof Matrix2
      @a = a.a
    else
      @a = new glMatrixArrayType(a)

  # **clone** - return a clone of this matrix
  # - returns new Matrix2
  clone: () ->
    new Matrix2(@a)

  # **copy** - copy all the values from another matrix, a
  # - **a** Matrix2
  # - 
  copy: (a) ->
    for i in [0..3]
      @a[i] = a.a[i]
    @

  # **multScalar** - multiply this matrix by a scalar
  multScalar: (n) ->
    @a = ( num * n for num in @a )
    @

  # **addScalar** - add a scalar to every element
  addScalar: (n) ->
    @a = ( num + n for num in @a )
    @

  # **subScalar** - remove a scalar from every element
  subScalar: (n) ->
    @a = ( num - n for num in @a )
    @

  # **divScalar** - divide every element by a scalar
  divScalar: (n) ->
    @a = ( num / n for num in @a)
    @

  # **identity** - set this matrix to be the identity matrix
  identity : ->
    @a.set([1,0,0,1])
    @
 
  # **flatten** - return the array part of this matrix
  flatten :() ->
    @a

  # **at** - return the element at the row and column specified
  at : (r,c) ->
    @a[c * 2 + r]

  # **mult** - multiply this matrix by matrix m
  mult: (m) ->

    a = new Matrix2()

    a.a[ 0] = @a[ 0]*m.a[ 0] + @a[ 2]*m.a[ 1]
    a.a[ 1] = @a[ 1]*m.a[ 0] + @a[ 3]*m.a[ 1]
    a.a[ 2] = @a[ 0]*m.a[ 2] + @a[ 2]*m.a[ 3]
    a.a[ 3] = @a[ 1]*m.a[ 2] + @a[ 3]*m.a[ 3]
   
    @copy(a)

    @

  # **multVec** - multiply vector v by this matrix - destructive to v
  # - **v** - Vec2
  # - returns this
  multVec: (v) ->
    if v.z? or v.w?
      PXLWarning "Mismatched vector and matrix dimensions"
      return
    x = @a[ 0]*v.x + @a[ 2]*v.y
    y = @a[ 1]*v.x + @a[ 3]*v.y

    v.x = x
    v.y = y
    @

  # **getCol** - return a column from this matrix as a Vec2
  # - **c** - Number
  # - returns List of Number - Length 2
  getCol: (c)->
    c = c * Matrix2.DIM
    Vec2 @a[c + 0] @a[c + 1]

  # **getRow** - return a row from this matrix as a Vec2
  # - **r** - Number
  # - returns List of Number - Length 2
  getRow: (r) ->
    Vec2 @a[r + 0] @a[r + 2]

      
  # **transpose** - transpose this matrix
  # - returns this
  transpose : () ->
    @copy new Matrix2 [@a[0],a[2],@a[1],@a[3]]
    @

  # **print** - print this matrix to the console
  # - returns this
  print: ()->
    console.log @a[0] + "," + @a[2]
    console.log @a[1] + "," + @a[3]
    @
  
  # **rotate** - given an angle in radians, set this as a rotation matrix
  # - **a** - Number
  # - returns this
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

  # **scale** - given a Vec3, create a scaling matrix
  # - **v** - Vec3
  # - returns this
  scale: (v) ->
    # Leave w
    r = new Matrix3()
    r.a[0] = v.x
    r.a[4] = v.y
    r.a[8] = v.z
    @mult(r)
    @


### Matrix3 ###
# A 3x3 matrix in Column Major Format

class Matrix3

  DIM : 3

  # **@addScalar** - static function - add a scalar to every element in this matrix
  # - **a** - Matrix3
  # - **b** - Number
  # - returns new Matrix3
  @addScalar:(a,b) ->
    a.clone()["addScalar"](b)

  # **@subScalar** - static function - subtract a scalar from every element in this matrix
  # - **a** - Matrix3
  # - **b** - Number
  # - returns new Matrix3
  @subScalar:(a,b) ->
    a.clone()["subScalar"](b)

  # **@multScalar** - static function - multiply every element in this matrix by a scalar
  # - **a** - Matrix3
  # - **b** - Number
  # - returns new Matrix3
  @multScalar:(a,b) ->
    a.clone()["multScalar"](b)

  # **@divScalar** - static function - divide every element in this matrix by a scalar
  # - **a** - Matrix3
  # - **b** - Number
  # - returns new Matrix3
  @divScalar:(a,b) ->
    a.clone()["divScalar"](b)

  # **@mult** - static function - multiply this matrix by another matrix
  # - **a** - Matrix3
  # - **b** - Matrix3
  # - returns new Matrix3
  @mult:(a,b) ->
    a.clone()["mult"](b)

  # **@invert** - static function - return the inverse of this matrix
  # - **a** - Matrix3
  # - returns new Matrix3
  @invert:(a) ->
    a["_invert"]()

  # **@multVec** - static function - multiply a vector by this matrix, returning a new vector
  # - **m** - Matrix3
  # - **v** - Vec3
  # - returns new Vec3
  @multVec: (m,v)->
    tv = v.clone()
    m.multVec(tv)
    tv

  # **@transpose** - static function - return the transpose of this matrix
  # - **a** - Matrix3
  # - returns new Matrix3
  @transpose:(a) ->
    new Matrix3([ a.a.a.a[0],a.a[3],a.a[6],a.a[1],a.a[4],a.a[7],a.a[2],a.a[5],a.a[8]])


  # **constructor**
  # - a - List of Number - Length 9 - Optional - Default [1.0,0.0,0.0,0.0,1.0,0.0,0.0,0.0,1.0]
  constructor: (a=[1.0,0.0,0.0,0.0,1.0,0.0,0.0,0.0,1.0]) ->
    if a instanceof Matrix3
      @a = a.a
    else
      @a = new glMatrixArrayType(a)

  # **clone** - return a clone of this matrix
  # - returns new Matrix3
  clone: () ->
    new Matrix3(@a)

  # **copy** - copy all the values from another matrix, a
  # - **a** - Matrix3
  # - returns this
  copy: (a) ->
    for i in [0..8]
      @a[i] = a.a[i]
    @

  # multScalar - multiply this matrix by a scalar
  # - **n** - Number
  # - returns this
  multScalar: (n) ->
    @a = ( num * n for num in @a )
    @

  # **addScalar** - add a scalar to every element
  # - **n** - Number
  # - returns this
  addScalar: (n) ->
    @a = ( num + n for num in @a )
    @

  # **subScalar** - remove a scalar from every element
  # - **n** - Number
  # - returns this
  subScalar: (n) ->
    @a = ( num - n for num in @a )
    @

  # **divScalar** - divide every element by a scalar
  # - **n** - Number
  # - returns this
  divScalar: (n) ->
    @a = ( num / n for num in @a)
    @

  # **identity** - set this matrix to be the identity matrix
  # - returns this
  identity : ->
    @a.set([1.0,0.0,0.0,0.0,1.0,0.0,0.0,0.0,1.0])
    @
  
  # **at** - return the element at the row and column specified
  # - **r** - Number
  # - **c** - Number
  # - returns Number
  at : (r,c) ->
    @a[c * 3 + r]

  # **mult** - multiply this matrix by matrix m
  # - **m** - Matrix3
  # - returns this
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
   
    @copy(a)

    @

 # **flatten** - return the array part of this matrix
  flatten :() ->
    @a


  # **multVec** - multiply vector v by this matrix - destructive to v
  # - **v** - Vec3
  # - returns this
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

  # **getCol** - return a column from this matrix as a Vec3
  # - **c** - Number
  # - returns Vec3
  getCol: (c)->
    c = c * Matrix3.DIM
    Vec3 @a[c + 0] @a[c + 1] @a[c + 2]

  # getRow - return a row from this matrix as a Vec3
  # - **r** - Number
  # - returns Vec3
  getRow: (r) ->
    Vec3 @a[r + 0] @a[r + 3] @a[r + 6]

  # ***_invert*** - invert this matrix
  # - Internal
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

  # **invert** - invert this matrix
  # - returns this
  invert: () ->
    @copy @_invert()
    @

 
  # **transpose** - transpose this matrix
  # - returns this
  transpose : () ->
    @copy new Matrix3([@a[0],@a[3],@a[6], @a[1],@a[4],@a[7], @a[2],@a[5],@a[8]])
    @

  # **print** - print this matrix to the console
  # - returns this
  print: ()->
    console.log @a[0] + "," + @a[3] + "," + @a[6]
    console.log @a[1] + "," + @a[4] + "," + @a[7]
    console.log @a[2] + "," + @a[5] + "," + @a[8]
  
  # **rotate** - given a Vec3 and an angle in radians, create a rotation matrix
  # - **v** - Vec3
  # - **a** - Number
  # - returns this
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

  # **scale** - given a Vec3, create a scaling matrix
  # - **v** - Vec3
  # - returns this
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

  # **@addScalar** - static function - adds a scalar to every element in the matrix
  # - **a** - Matrix4
  # - **b** - Number
  # - returns new Matrix4
  @addScalar:(a,b) ->
    a.clone()["addScalar"](b)

  # **@subScalar** - static function - subtract a scalar from every element in this matrix
  # - **a** - Matrix4
  # - **b** - Number
  # - returns new Matrix4
  @subScalar:(a,b) ->
    a.clone()["subScalar"](b)

  # **@multScalar** - static function - multiply every element in this matrix by a scalar
  # - **a** - Matrix4
  # - **b** - Number
  # - returns new Matrix4
  @multScalar:(a,b) ->
    a.clone()["multScalar"](b)

  # **@divScalar** - static function - divide every element in this matrix by a scalar
  # - **a** - Matrix4
  # - **b** - Number
  # - returns new Matrix4
  @divScalar:(a,b) ->
    a.clone()["divScalar"](b)

  # **@mult** - static function - multiply this matrix by another matrix
  # - **a** - Matrix4
  # - **b** - Matrix4
  # - returns new Matrix4
  @mult:(a,b) ->
    a.clone()["mult"](b)

  # **@invert** - static function - return the inverse of this matrix
  # - **a** - Matrix4
  # - returns new Matrix4
  @invert:(a) ->
    a["_invert"]()

  # **@transpose** - static function - return the transpose of this matrix
  # - **a** - Matrix4
  # - returns new Matrix4
  @transpose:(a) ->
    new Matrix4( [ a.a[0], a.a[4], a.a[8], a.a[12], a.a[1], a.a[5], a.a[9], a.a[13], a.a[2], a.a[6], a.a[10], a.a[14], a.a[3], a.a[7], a.a[11], a.a[15] ] )


  # **@multVec** - static function - multiply a vector by this matrix, returning a new vector
  # - **m** - Matrix4
  # - **v** - Vec4
  # - returns new Vec4
  @multVec: (m,v)->
    tv = v.clone()
    m.multVec(tv)
    tv

  # **constructor**
  # - **a** - List of Number - Length 16 - Optional - Default [1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1]
  constructor: (a=[1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1]) ->
    if a instanceof Matrix4
      @a = a.a
    else
      @a = new glMatrixArrayType(a)

  # **clone** - return a clone of this matrix
  # - returns new Matrix4
  clone: () ->
    new Matrix4(@a)

  # **copy** - copy all the values from another matrix, a
  # - **a** - Matrix4
  # - returns this
  copy: (a) ->
    for i in [0..15]
      @a[i] = a.a[i]
    @

  # **multScalar** - multiply this matrix by a scalar
  # - **n** - Number
  # - returns this
  multScalar: (n) ->
    @a = ( num * n for num in @a )
    @

  # **addScalar** - add a scalar to every element
  # - **n** - Number
  # - returns this
  addScalar: (n) ->
    @a = ( num + n for num in @a )
    @

  # **subScalar** - remove a scalar from every element
  # - **n** - Number
  # - returns this
  subScalar: (n) ->
    @a = ( num - n for num in @a )
    @

  # **divScalar** - divide every element by a scalar
  # - **n** - Number
  # - returns this
  divScalar: (n) ->
    @a = ( num / n for num in @a)
    @

  # **identity** - set this matrix to be the identity matrix
  # - returns this
  identity : ->
    @a.set([1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1])
    @
  
  # **at** - return the element at the row and column specified
  # - **r** - Number
  # - **c** - Number
  # - returns Number
  at : (r,c) ->
    @a[c * 4 + r]

  # **getMatrix**3 - return the 3x3 matrix from this 4x4 - top left part
  # - returns new Matrix3
  getMatrix3 : () ->
    new Matrix3([ @a[0],@a[1],@a[2],@a[4],@a[5],@a[6],@a[8],@a[9],@a[10]])

  # **mult** - multiply this matrix by matrix m
  # - **m** - Matrix4
  # - returns this
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

    @copy(a)
    @

  # **flatten** - return the array part of this matrix
  flatten :() ->
    @a

  # **multVec** - multiply vector v by this matrix - destructive to v
  # - **v** - Vec4
  # - returns
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

  # **at** - return the number at row r and column c
  # - **r** - Number
  # - **c** - Number
  # - returns Number
  at: (r,c) ->
    @a[c * 4 + r]

  # **getCol** - return a column from this matrix as a Vec4
  # - **c** - Number
  # - returns Vec4
  getCol: (c)->
    c = c * 4
    Vec4 @a[c + 0] @a[c + 1] @a[c + 2] @a[c + 3]

  # **getRow** - return a row from this matrix as a Vec4
  # - **r** - Number
  # - returns Vec4
  getRow: (r) ->
    Vec4 @a[r + 0] @a[r + 4] @a[r + 8] @a[r + 12]

  # **_invert** - internal
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

  # **invert** - invert this matrix
  # - returns this
  invert: () ->
    @copy @_invert() 
    @

  # **transpose** - transpose this matrix
  # - returns this
  transpose : () ->
    @copy new Matrix4( [ @a[0],@a[4],@a[8],@a[12],@a[1],@a[5],@a[9],@a[13],@a[2],@a[6],@a[10],@a[14],@a[3],@a[7],@a[11],@a[15] ] )
    @


  # translate - multiple this matrix by a translation matrix, formed from the Vec3 v
  # - **v** - Vec3
  # - returns this
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

  # **setPos** - Given a vector, sets the translation part of the matrix directly with no multiplication
  # - **v** - Vec3
  # - returns this
  setPos : (v) ->
    @a[12] = v.x if v.x?
    @a[13] = v.y if v.y?
    @a[14] = v.z if v.z?
    @

  # **getPos** - return the translation component as a Vec3
  # - returns new Vec3
  getPos : () ->
    return new Vec3 @a[12],@a[13],@a[14]
  
  # **print** - print this matrix to the console
  # - returns this
  print: ()->
    console.log @a[0] + "," + @a[4] + "," + @a[8] + "," + @a[12]
    console.log @a[1] + "," + @a[5] + "," + @a[9] + "," + @a[13]
    console.log @a[2] + "," + @a[6] + "," + @a[10] + "," + @a[14]
    console.log @a[3] + "," + @a[7] + "," + @a[11] + "," + @a[15]
    @


  # lookAt - similar to gluLookAt - creates a matrix from an eye, look and up vector (Vec3)
  lookAt: (eye,look,up) ->

    f = Vec3.sub(look,eye)
    f.normalize()
    u = up.clone()
    u.normalize()

    s = Vec3.cross(f,u)
    w = Vec3.cross(s,f)

    m = new Matrix4([s.x,u.x,-f.x,0,s.y,u.y,-f.y,0,s.z,u.z,-f.z,0,0,0,0,1])
    t = new Matrix4([1,0,0,0,0,1,0,0,0,0,1,0, -eye.x,-eye.y,-eye.z,1])

    m.mult(t)
    @copy(m)
    @


  # makePerspective - given a field-of-view in degrees, an aspect ratio (w/h) and near and far clip planes
  # create a perspective matrix

  makePerspective: (fovy,aspect,znear,zfar) ->
    ymax = znear * Math.tan(fovy)
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

  # **@addScalar** - static function - add a scalar to every element in this quaternion
  @addScalar:(a,b) ->
    a.clone()["addScalar"](b)

  # **@subScalar** - static function - subtract a scalar from every element in this quaternion
  @subScalar:(a,b) ->
    a.clone()["subScalar"](b)

  # **@multScalar** - static function - multiply every element in this quaternion by a scalar
  @multScalar:(a,b) ->
    a.clone()["multScalar"](b)

  # **@divScalar** - static function - divide every element in this quaternion by a scalar
  @divScalar:(a,b) ->
    a.clone()["divScalar"](b)

  # **@conjugate** - static function - return the conjugate to this quaternion
  @conjugate:(a) ->
    a.clone()["conjugate"]()

  # **@mult** - static function - multiply this quaternion by another quaternion
  @mult:(a,b) ->
    a.clone()["mult"](b)

  # **@invert** - static function - return an inverted version
  @invert:(a) ->
    a.clone()["invert"]()
 
  # transVec3 - static function - given a vector, return a new version of it, transformed by this quaternion
  @transVec3:(q,v) ->
    tv = v.clone()
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

  # clone - return a coy of this Quaternion
  clone: () ->
    new Quaternion @x, @y, @z, @w
 
  # copy - copy another quaternion into this one
  copy: (q) ->
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
    d = @clone()
    d.sub(end)
    lengthD = Math.sqrt(@dot(end))
    st = @clone()
    st.add(end)
    lengthS = Math.sqrt(st.dot(st))

    a = 2 * Math.atan2(lengthD,lengthS)
    s = 1 - t

    q = @clone()
    q.multScalar(( sinx_over_x( s * a ) / sinx_over_x( a ) * s ) )
    e = end.clone()
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
   
    q = @clone()
    q.mult(startInterp)
    e = end.clone()
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


