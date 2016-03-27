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

chai = require 'chai'
chai.should()

PXLAnim = require '../src/animation/animation'
PXLMath = require '../src/math/math'

describe 'Animation tests: ', ->
  animator = new PXLAnim.Animator(21,24,"test anim")
  
  
  it 'Animated value should equal 15,1,1 on frame 15', ->

    val = new PXLMath.Vec3(1,1,1)

    k0 = new PXLAnim.KeyFrame val, new PXLMath.Vec3(10,1,1), 10
    k1 = new PXLAnim.KeyFrame val, new PXLMath.Vec3(20,1,1), 20
    t0 = new PXLAnim.Tween k0,k1

    animator.addTween t0

    # take the next 5 frames, stepping through
    for n in [0..14]
      animator.step 1.0/24.0
    
    chai.assert.deepEqual([val.x, val.y, val.z],[15,1,1])




