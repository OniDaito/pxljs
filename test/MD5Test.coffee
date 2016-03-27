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
 
Testing the MD5 Model loading class

###

chai = require 'chai'
chai.should()

PXLMath = require '../src/math/math'
PXLMD5 = require '../src/import/md5'

fs = require 'fs'

describe 'MD5 tests: ', ->
  
  # Not sure I'm happy with the dirname relative stuff but it seems to work :)
  md5 = new PXLMD5.MD5Model( __dirname + "/../html/models/hellknight/hellknight.md5mesh")
  md5.skeleton.update()


  it 'md5 version should be 10', ->
    md5.version.should.equal "10"

  it 'md5 hellknight has 110 joints', ->
    md5.num_joints.should.equal 110

  it 'md5 hellknight should have four child nodes', ->
    md5.children.length.should.equal 4

  it 'md5 bone 10 should be "lhand"', ->
    md5.skeleton.bones[10].name.should.equal "lhand"

  it 'md5 vertex 2 on mesh 0 should be 3.36169,-20.2517,100.319', ->
    Math.round(md5.children[0].geometry.vertices[2].p.x).should.equal 3
    #Math.round(md5.children[0].geometry.vertices[2].p.y).should.equal -20
    Math.round(md5.children[0].geometry.vertices[2].p.z).should.equal 100
    Math.round(md5.children[0].geometry.vertices[2].p.y).should.equal -20
  it 'md5 vertex 100 on mesh 0 should be 20.4423, -9.70051, 49.5357', ->
    Math.round(md5.children[0].geometry.vertices[100].p.x).should.equal 20
    Math.round(md5.children[0].geometry.vertices[100].p.y).should.equal -10
    Math.round(md5.children[0].geometry.vertices[100].p.z).should.equal 50

  it 'md5 luparm pose rotation matrix should match C++ Version', ->
    m = new PXLMath.Matrix4()
    q = md5.skeleton.getBoneByName("luparm").rotation_pose
    m.mult(q.getMatrix4())
    b = []
    for n in m.a 
      # Round to two decimal places
      b.push Math.round(n * 100) / 100 

    rot_real = [0.86, 0.24, -0.44, 0, -0.15, 0.96, 0.22, 0, 0.48, -0.12, 0.87, 0, 0, 0, 0, 1]
    chai.assert.deepEqual(b,rot_real)

  it 'md5 waist pose rotation matrix should match C++ Version', ->
    m = new PXLMath.Matrix4()
    q = md5.skeleton.getBoneByName("waist").rotation_pose
    m.mult(q.getMatrix4())
    b = []
    for n in m.a 
      # Round to two decimal places
      b.push Math.round(n * 100) / 100 

    rot_real = [1,0,0,0,0,0,1,0,0,-1,0,0,0,0,0,1]
    chai.assert.deepEqual(b,rot_real)

  it 'md5 rwrist global rotation matrix should match C++ Version', ->
    m = new PXLMath.Matrix4()
    q = md5.skeleton.getBoneByName("rwrist").rotation_global
    m.mult(q.getMatrix4())
    b = []
    for n in m.a 
      # Round to two decimal places
      b.push Math.round(n * 100) / 100 

    rot_real = [0.71,0.44,0.55,0,-0.38,0.9,-0.22,0,-0.59,-0.05,0.81,0,0,0,0,1]
    chai.assert.deepEqual(b,rot_real)



  it 'md5 rwrist skinned rotation matrix should match C++ Version', ->
    m = md5.skeleton.getBoneByName("rwrist").skinned_matrix
    b = []
    for n in m.a 
      # Round to two decimal places
      b.push Math.round(n * 100) / 100 

    rot_real = [1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1]
    chai.assert.deepEqual(b,rot_real)

  it 'md5 rwrist position vector should match C++ Version', ->
    #md5.skeleton.update()
    v = md5.skeleton.getBoneByName("rwrist").position_relative
    
    round  = (n) ->
      Math.round(n * 100) / 100 
    
    b = [round(v.x), round(v.y), round(v.z)]

    rot_real = [-6.86, 0.23, -1.31]
    chai.assert.deepEqual(b,rot_real)

  
  it 'md5 rwrist Quaternion should match C++ Version', ->
    v = md5.skeleton.getBoneByName("rwrist").rotation_relative
    round = (x) ->
      Math.round(x * 100) / 100 
    b = [round(v.x),round(v.y),round(v.z),round(v.w)]
    
    rot_real = [0.59, -0.22, 0.16,0.76]
    chai.assert.deepEqual(b,rot_real)

  it 'md5 rwrist position vector pose should match C++ Version', ->
    v = md5.skeleton.getBoneByName("rwrist").position_pose
    round = (x) ->
      Math.round(x * 100) / 100 

    b = [round(v.x), round(v.y), round(v.z)]
    rot_real = [-41.19, 5.21, 96.32]
    chai.assert.deepEqual(b,rot_real)
