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

PXLJSPromise = require '../src/util/promise'

fs = require 'fs'

describe 'Promise tests: ', ->

   it 'Create one Promise and have it return', ->

    testing = () ->

      p = new PXLJSPromise.Promise()

      dostuff = () =>
        value = "resolved"
        p.resolve value

      [p,dostuff]

    [p,dostuff] = testing()
    
    final_value = ""
    p.then (value) =>
      final_value = value

    dostuff()

    final_value.should.equal "resolved"

  it 'Create two promises as conditions of one promise', ->

    p0 = new PXLJSPromise.Promise()
    p1 = new PXLJSPromise.Promise()
    
    final_value = ""
    master_promise = new PXLJSPromise.Promise()

    success = (value0, value1) =>
      final_value = value0 + " " + value1

    master_promise.when(p0, p1).then(success)

    # deliberately out of order
    p1.resolve "resolved one"
    p0.resolve "resolved zero"

    final_value.should.equal "resolved zero resolved one"