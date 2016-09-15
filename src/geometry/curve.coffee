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

{Vec2, Vec3, PI, degToRad} = require '../math/math'

### CurveLine ###
# Base class for a curve that is considered drawable to the screen as oppose
# to a purely mathematical one.
# Pass in a mathematical curve such as a quadratic bezier and this will generate
# the geometry for us. In this case, a line

class CurveLine extends Geometry

  # **@constructor** 
  # - **math_curve** - a Curve
  # - **rez** - a Number - Optional - Default 200
  constructor : (math_curve, rez=200)->
    super()

    @indexed = false

module.exports =
  CurveLine: CurveLine
