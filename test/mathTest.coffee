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

Maths Tests
http://net.tutsplus.com/tutorials/javascript-ajax/better-coffeescript-testing-with-mocha/
http://visionmedia.github.com/mocha/

###

chai = require 'chai'
chai.should()


PXLMath = require '../src/math/math'
PXLCamera = require '../src/camera/camera' 
PXLCurve = require '../src/math/curve'
PXLUberPath = require '../src/gl/uber_shader_paths'

describe 'Maths tests: ', ->
  q = new PXLMath.Quaternion()
  it 'Quaternion should not be undefined', ->
  q.should.not.equal undefined

  it 'Quaternion should not affect a matrix', ->
    m = new PXLMath.Matrix4()
    q.fromAxisAngle(new PXLMath.Vec3(0,1,0),PXLMath.degToRad(0))
    m.mult(q.getMatrix4())
    b = []
    for n in m.a 
      b.push n

    chai.assert.deepEqual(b,[1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1])

  it 'Quaternion should create a 90 degree rotation matrix and rotate back from axis angle', ->
    m = new PXLMath.Matrix4()
    m.translate(new PXLMath.Vec3(0,0,1))
    q.fromAxisAngle(new PXLMath.Vec3(0,1,0),PXLMath.degToRad(90))
    m.mult(q.getMatrix4())

    theta = PXLMath.degToRad(90)

    r = [Math.cos(theta),0,-Math.sin(theta),0, 0,1,0,0, Math.sin(theta),0, Math.cos(theta),0,0,0,1,1]

    EPSILON = 1.0e-6

    for n in [0..15]
      a = m.a[n]
      b = r[n]
      
      (Math.abs(Math.abs(a) - Math.abs(b)) < EPSILON).should.be.true

    q.fromAxisAngle(new PXLMath.Vec3(0,1,0),PXLMath.degToRad(-90))
    m.mult(q.getMatrix4())

    b = []
    for n in m.a 
      b.push n
    chai.assert.deepEqual(b,[1,0,0,0,0,1,0,0,0,0,1,0,0,0,1,1])

  it 'Quaternion 90 Degree should transform (2,0,0) to (0,0,-2)', ->
    q.fromAxisAngle(new PXLMath.Vec3(0,1,0),PXLMath.degToRad(90))
    v = new PXLMath.Vec3(2,0,0)
    theta = PXLMath.degToRad(90)
    q.transVec3(v)

    EPSILON = 1.0e-6

    a = [v.x,v.y,v.z]
    b = [0,0,-2]

    for n in [0..2]
      c = a[n]
      d = b[n]
      (Math.abs(Math.abs(c) - Math.abs(d)) < EPSILON).should.be.true


  it 'Quaternion should create a 90 degree rotation matrix and rotate back from 3 euler angles', ->
    m = new PXLMath.Matrix4()
    m.translate(new PXLMath.Vec3(0,0,1))
    q.fromRotations 0,PXLMath.degToRad(90),0
    m.mult(q.getMatrix4())

    theta = PXLMath.degToRad(90)

    r = [Math.cos(theta),0,-Math.sin(theta),0, 0,1,0,0, Math.sin(theta),0, Math.cos(theta),0,0,0,1,1]

    EPSILON = 1.0e-6

    for n in [0..15]
      a = m.a[n]
      b = r[n]
      (Math.abs(Math.abs(a) - Math.abs(b)) < EPSILON).should.be.true

    q.fromRotations 0,PXLMath.degToRad(-90),0
    m.mult(q.getMatrix4())

    b = []
    for n in m.a 
      b.push n
    chai.assert.deepEqual(b,[1,0,0,0,0,1,0,0,0,0,1,0,0,0,1,1])


  it 'Two Quaternions multiplied together should cancel out if they are opposite', ->
    m = new PXLMath.Matrix4()
    qa = new PXLMath.Quaternion()
    qb = new PXLMath.Quaternion()
    m.translate(new PXLMath.Vec3(0,0,1))
    qa.fromRotations 0,PXLMath.degToRad(90),0
    qb.fromRotations 0,PXLMath.degToRad(-90),0
    qa.mult(qb).normalize()

    m.mult(qa.getMatrix4())
    
    b = []
    for n in m.a 
      b.push n
    chai.assert.deepEqual(b,[1,0,0,0,0,1,0,0,0,0,1,0,0,0,1,1])

  it 'Quaternion should invert properly', ->
    qa = new PXLMath.Quaternion()
    qb = new PXLMath.Quaternion()
    qa.fromRotations 0,PXLMath.degToRad(90),0
    qb.fromRotations 0,PXLMath.degToRad(-90),0
    qc = PXLMath.Quaternion.invert(qa)

    (qb.x == qc.x && qb.y == qc.y && qb.z == qc.z && qb.w == qc.w).should.be.true


  it 'Quaternion should rotate a vector properly', ->
    qa = new PXLMath.Quaternion()
    qa.fromRotations 0,PXLMath.degToRad(90),0
    va = new PXLMath.Vec3(0,0,-1)
    qa.transVec3 va
    round  = (n) ->
      Math.round(n * 100) / 100 
    (round(va.x) == 1 && round(va.y) == 0 && round(va.z) == 0).should.be.true

  it 'Matrix4x4 should be identity', ->
    m = new PXLMath.Matrix4()
    b = []
    for n in m.a 
      b.push n
    chai.assert.deepEqual(b,[1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1])

  it 'Matrix4x4 should inverse properly', ->
    m = new PXLMath.Matrix4([1,0,0,0, 0,1,0,0, 0,0,1,0, 2,2,2,1])
    i = PXLMath.Matrix4.invert(m)
    b = []
    for n in i.a 
      b.push n
    chai.assert.deepEqual(b,[1,0,0,0, 0,1,0,0, 0,0,1,0, -2,-2,-2,1])


  it 'Matrix4x4 should transpose properly', ->
    m = new PXLMath.Matrix4([1,0,0,0, 0,1,0,0, 0,0,1,0, 2,2,2,1])
    i = PXLMath.Matrix4.transpose(m)
    b = []
    for n in i.a 
      b.push n
    chai.assert.deepEqual(b,[1,0,0,2,0,1,0,2,0,0,1,2,0,0,0,1])


  it 'Matrix4x4 should return a proper matrix3x3', ->
    m = new PXLMath.Matrix4([1,0,0,0, 0,1,0,0, 0,0,1,0, 2,2,2,1])
    i = m.getMatrix3()
    b = []
    for n in i.a 
      b.push n
    chai.assert.deepEqual(b,[1,0,0,0,1,0,0,0,1])


  it 'Matrix3x3 should be identity', ->
    m = new PXLMath.Matrix3()
    b = []
    for n in m.a 
      b.push n
    chai.assert.deepEqual(b,[1,0,0,0,1,0,0,0,1])

  it 'Matrix3x3 should inverse properly', ->
    m = new PXLMath.Matrix3([1,0,5,2,1,6,3,4,0])
    m.invert()
    b = []
    for n in m.a 
      b.push n
    chai.assert.deepEqual(b,[-24,20,-5,18,-15,4,5,-4,1])

  it 'Matrix3x3 should transpose properly', ->
    m = new PXLMath.Matrix3([1,0,5,2,1,6,3,4,0])
    m.transpose()
    b = []
    for n in m.a 
      b.push n
    chai.assert.deepEqual(b,[1,2,3,0,1,4,5,6,0])


  it 'Matrix3x3 should rotate properly', ->
    m = new PXLMath.Matrix3()
    m.rotate new PXLMath.Vec3(0,1,0), PXLMath.degToRad 90
    n = new PXLMath.Vec3(1,0,0)
    m.multVec n
    r = n.flatten()
    q = [0,0,-1]

    EPSILON = 1.0e-6

    for n in [0..2]
      a = r[n]
      b = q[n]
      (a-b < EPSILON).should.be.true

  it 'CatmullRomSpline of 4 points should interpolate nicely', ->
    p0 = new PXLMath.Vec2(0,0)
    p1 = new PXLMath.Vec2(1,0)
    p2 = new PXLMath.Vec2(2,0)
    p3 = new PXLMath.Vec2(3,0)
    c = new PXLCurve.CatmullRomSpline([p0,p1,p2,p3] )

    a = c.pointOnCurve(0.5)
    b = new PXLMath.Vec2(1.5,0)
    EPSILON = 1.0e-6
    (a.sub(b).length() < EPSILON).should.be.true

    a = c.pointOnCurve(0.0)
    b = new PXLMath.Vec2(1.0,0)
    EPSILON = 1.0e-6
    (a.sub(b).length() < EPSILON).should.be.true

    a = c.pointOnCurve(1.0)
    b = new PXLMath.Vec2(2.0,0)
    EPSILON = 1.0e-6
    (a.sub(b).length() < EPSILON).should.be.true

  it 'CatmullRomSpline of 5 points should interpolate nicely', ->

    p0 = new PXLMath.Vec2(0,0)
    p1 = new PXLMath.Vec2(1,0)
    p2 = new PXLMath.Vec2(2,0)
    p3 = new PXLMath.Vec2(3,0)
    p4 = new PXLMath.Vec2(4,0)
    c = new PXLCurve.CatmullRomSpline([p0,p1,p2,p3,p4] )

    a = c.pointOnCurve(0.5)
    b = new PXLMath.Vec2(2.0,0)
    EPSILON = 1.0e-6
    (a.sub(b).length() < EPSILON).should.be.true

    a = c.pointOnCurve(0.0)
    b = new PXLMath.Vec2(1.0,0)
    EPSILON = 1.0e-6
    (a.sub(b).length() < EPSILON).should.be.true

    a = c.pointOnCurve(1.0)
    b = new PXLMath.Vec2(3.0,0)
    EPSILON = 1.0e-6
    (a.sub(b).length() < EPSILON).should.be.true

    ###
    it 'y value for a parabola with abitrary directrix', ->
      p0 = new PXLMath.Parabola(new PXLMath.Vec2(0,1),-0.5,0.5,0)
      y = p0.sample(0.0)
      EPSILON = 1.0e-6

      (Math.abs(y[0] - 0.5857864376) < EPSILON).should.be.true
      (Math.abs(y[1] - 3.4142135623) < EPSILON).should.be.true

      y = p0.sample(-2.5)

      (Math.abs(y[0] - 1.035898384) < EPSILON).should.be.true
      (Math.abs(y[1] - 7.964101615) < EPSILON).should.be.true

    it 'y value for a parabola with an X axis directrix', ->
      p0 = new PXLMath.Parabola(new PXLMath.Vec2(0,2),0,1.0,0.0)
      y = p0.sample(0.0)
      EPSILON = 1.0e-6
      (Math.abs(y[0] - 1.0) < EPSILON).should.be.true

      p0 = new PXLMath.Parabola(new PXLMath.Vec2(0,2),0,1.0,1.0)
      y = p0.sample(0.0)
      (Math.abs(y[0] - 1.5) < EPSILON).should.be.true

    it 'y value for a parabola with an Y axis directrix', ->
      p0 = new PXLMath.Parabola(new PXLMath.Vec2(2,0),1.0,0.0,0.0)
      y = p0.sample(1.1)
      EPSILON = 1.0e-6
      (Math.abs(y[0] - 0.6324555320336761) < EPSILON).should.be.true
      (Math.abs(y[1] + 0.6324555320336761) < EPSILON).should.be.true

      #p0 = new PXLMath.Parabola(new PXLMath.Vec2(2,0),1.0,0.0,1.0)
      #y = p0.sample(0.0)
      #console.log y
      #(Math.abs(y[0] + 1.5) < EPSILON).should.be.true
      #(Math.abs(y[1] - 1.5) < EPSILON).should.be.true

    it 'Crossing point for a parabola', ->
      p0 = new PXLMath.Parabola(new PXLMath.Vec2(2,2),1.0,1.0,0.0)
      [s0,s1] = p0.lineCrossing -1,-1,5
   
      EPSILON = 1.0e-6
      (Math.abs(s0.x - 0.05051025721682212) < EPSILON).should.be.true
      (Math.abs(s0.y - 4.949489742783178) < EPSILON).should.be.true

      (Math.abs(s1.x - 4.949489742783178) < EPSILON).should.be.true
      (Math.abs(s1.y - 0.05051025721682212) < EPSILON).should.be.true

      p1 = new PXLMath.Parabola(new PXLMath.Vec2(0,2),3.0,-2.0,-1.0)
      [s0,s1] = p1.lineCrossing -1,-1,5

      (Math.abs(s0.x + 32.1245154965971) < EPSILON).should.be.true
      (Math.abs(s0.y - 37.1245154965971) < EPSILON).should.be.true

      (Math.abs(s1.x - 0.12451549659709826) < EPSILON).should.be.true
      (Math.abs(s1.y - 4.875484503402902) < EPSILON).should.be.true
    ###

  it 'Catmull Patch', ->
    p0 = new PXLMath.Vec3(0,0,0)
    p1 = new PXLMath.Vec3(0,0,1)
    p2 = new PXLMath.Vec3(0,0,2)
    p3 = new PXLMath.Vec3(0,0,3)

    p4 = new PXLMath.Vec3(2,0,0)
    p5 = new PXLMath.Vec3(2,1,1)
    p6 = new PXLMath.Vec3(2,1,2)
    p7 = new PXLMath.Vec3(2,0,3)

    p8 = new PXLMath.Vec3(4,0,0)
    p9 = new PXLMath.Vec3(4,1,1)
    p10 = new PXLMath.Vec3(4,1,2)
    p11 = new PXLMath.Vec3(4,0,3)

    p12 = new PXLMath.Vec3(8,0,0)
    p13 = new PXLMath.Vec3(8,0,1)
    p14 = new PXLMath.Vec3(8,0,2)
    p15 = new PXLMath.Vec3(8,0,3)

    points = [p0,p1,p2,p3,p4,p5,p6,p6,p8,p9,p10,p11,p12,p13,p14,p15]

    cm = new PXLCurve.CatmullPatch(points)

    EPSILON = 1.0e-6

    tp = cm.sample( new PXLMath.Vec2(0.0, 0.0) )
    (Math.abs(tp.x - 2) < EPSILON).should.be.true
    (Math.abs(tp.y - 1) < EPSILON).should.be.true
    (Math.abs(tp.z - 1) < EPSILON).should.be.true

    tp = cm.sample( new PXLMath.Vec2(0.5, 0.25) )
    (Math.abs(tp.x - 2.453125) < EPSILON).should.be.true
    (Math.abs(tp.y - 1.17626953125) < EPSILON).should.be.true
    (Math.abs(tp.z - 1.55419921875) < EPSILON).should.be.true

    tp = cm.sample( new PXLMath.Vec2(1.0, 1.0) )
    (Math.abs(tp.x - 4) < EPSILON).should.be.true
    (Math.abs(tp.y - 1) < EPSILON).should.be.true
    (Math.abs(tp.z - 2) < EPSILON).should.be.true

  
  it 'Matrix Project and Un-Project', ->
    c = new PXLCamera.PerspCamera new PXLMath.Vec3 0,0,10
    
    c.m.lookAt c.pos, c.look, c.up
    c.p.makePerspective(50, 640 / 480, 0.1, 100.0 )

    tp = new PXLMath.Vec4 1,1,1,1
    tm = PXLMath.Matrix4.mult c.p, c.m
    tm.multVec(tp)

    tt =  new PXLMath.Vec4 tp.x / tp.w, tp.y / tp.w, tp.z / tp.w, 1

    #console.log tt


  it 'Ray Cast', ->
    
    EPSILON = 1.0e-6
    c = new PXLCamera.PerspCamera new PXLMath.Vec3(0,0,4.0),
      new PXLMath.Vec3(0,0,0), new PXLMath.Vec3(0,1,0), 55.0, 0.1, 10.0

    c.update 640,480
    tt = c.castRay 320,240,640,480

    (Math.abs(tt.x ) < EPSILON).should.be.true
    (Math.abs(tt.y ) < EPSILON).should.be.true
    (Math.abs(tt.z + 1) < EPSILON).should.be.true

    c = new PXLCamera.PerspCamera new PXLMath.Vec3(0,0,-4.0),
      new PXLMath.Vec3(0,0,0), new PXLMath.Vec3(0,1,0), 55.0, 0.1, 10.0
    c.update 640,480


    #tt = c.castRay 640,480,640,480
    
    #console.log (tt) 
 
    #(Math.abs(tt.x + 0.5242704794481596) < EPSILON).should.be.true
    #(Math.abs(tt.y + 0.3932028797167508) < EPSILON).should.be.true
    #(Math.abs(tt.z - 0.7553356603270172) < EPSILON).should.be.true

  it 'bit operation on uber shader path', ->
    (PXLUberPath.uber_clear_material(2) == 2).should.be.true



