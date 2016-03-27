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
Tree Tests
http://net.tutsplus.com/tutorials/javascript-ajax/better-coffeescript-testing-with-mocha/
http://visionmedia.github.com/mocha/

###

chai = require 'chai'
chai.should()

PXLMath = require '../src/math/math'
PXLCamera = require '../src/camera/camera'
PXLPrimitive = require '../src/geometry/primitive'
PXLPlane = require '../src/geometry/plane'

describe 'Geometry tests: ', ->
  
  hex = new PXLPlane.PlaneHexagonFlat(21,9)

  it 'Hex should not be undefined', ->
    hex.should.not.equal undefined


  it 'Hex Point interators should match', ->
    indexer = hex.getTrisIndexer()
    [a,b,c] = indexer(0)
    [a,b,c] = indexer(1)
    [a,b,c] = indexer(2)

