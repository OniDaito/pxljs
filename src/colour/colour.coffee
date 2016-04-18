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


### RGBA ###
# The default colour - four floats 0 -> 1 for representing colour

class RGBA

  DIM : 4 

  constructor: (@r=1.0, @g=1.0, @b=1.0, @a=1.0) ->
    # Check for byte colours
    
    if @r > 1.0
      @r = @r / 255

    if @g > 1.0
      @g = @g / 255

    if @b > 1.0
      @b = @b / 255

    if @a > 1.0
      @a = @a / 255

  # flatten - used in the shader class to flatten the variables into a nice list
  flatten: ->
    [@r,@g,@b,@a]

  # @WHITE - Static function that returns the default white
  @WHITE : () ->
    new RGBA(1.0,1.0,1.0,1.0)

  # @BLACK - Static function that returns all zeros including alpha (not black I guess?)
  @BLACK : () ->
    new RGBA(0.0,0.0,0.0,1.0)

  @MAGNOLIA : () ->
    new RGBA(1.0,1.0,0.9,1.0)

  copyFrom: (col) ->
    @r = col.r
    @g = col.g
    @b = col.b
    @a = col.a
    @

  copy : () ->
    new RGBA @r,@g,@b,@a


### RGB ###
# Class for colours with no alpha

class RGB 

  DIM : 3

  constructor: (@r, @g, @b) ->

    if @r > 1.0
      @r = @r / 255

    if @b > 1.0
      @g = @g / 255

    if @g > 1.0
      @b = @b / 255

  # flatten - used in the shader class to flatten the variables into a nice list
  flatten: ->
    [@r,@g,@b]

  # @WHITE - Static function that returns the default white
  @WHITE : () ->
    new RGB(1.0,1.0,1.0)

  # @BLACK - Static function that returns all zeros including alpha (not black I guess?)
  @BLACK : () ->
    new RGB(0.0,0.0,0.0)

  @MAGNOLIA : () ->
    new RGBA(1.0,1.0,0.9)


  copyFrom : (c) ->
    @r = c.r
    @g = c.g
    @b = c.b
    @

  copy : () ->
    new RGB @r,@g,@b

module.exports = 
    RGBA: RGBA
    RGB : RGB
