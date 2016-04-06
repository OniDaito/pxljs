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

- Resources

* http://www.yuiblog.com/blog/2007/06/12/module-pattern/
* http://www.plexical.com/blog/2012/01/25/writing-coffeescript-for-browser-and-nod/
* https://github.com/field/FieldKit.js

- TODO
* Need a shorthand here for sure!

###

### PXL entry point ###

# Setting up a namespace this way instead of with a function as we are using npm and
# Browserify. We effectively go with a mixin strategy, treating the namespace as an
# object (which it always was). We override the effects of rquires with util.extend
# Without util.extend we dont quite get the namespace effect when we browserify

PXL = {}
GL = {} # Global GL - Is overwritten often - Shorthand for PXL.Context.gl

util = require './util/util'

# extend - adds objects to our master coffeegl object, namespace style
extend = ->
  switch arguments.length
    when 1
      util.extend PXL, arguments[0]

    when 2
      pkg = arguments[0]
      PXL[pkg] = {} if not PXL[pkg]?
      util.extend PXL[pkg], arguments[1]

# If we are in a browser add to the window object
window.PXL = PXL if window?
window.GL = GL if window?

# Add extra classes to our coffeegl namespace

extend require './core/app'
extend require './core/node'

extend "Math", require './math/math'
extend "Math", require './math/curve'
extend "Math", require './math//math_functions'

extend "Colour", require './colour/colour'

extend "Geometry", require './geometry/primitive'
extend "Geometry", require './geometry/shape'

extend "Import", require './import/three'
extend "Import", require './import/obj'
extend "Import", require './import/md5'

extend "GL", require './gl/shader'
extend "GL", require './gl/uber_shader_paths'
extend "GL", require './gl/uber_shader'
extend "GL", require './gl/fbo'
extend "GL", require './gl/texture'
extend "GL", require './gl/webgl'

extend "Util", require './util/request'
extend "Util", require './util/promise'
extend "Util", require './util/util'
extend "Util", require './util/signal'
extend "Util", require './util/log'
extend "Util", require './util/voronoi'
extend "Util", require './util/medial_axis'
extend "Util", require './util/webcam'
extend "Util", require './util/noise'
extend "Util", require './util/cache_var'

extend "Interact", require './interact/key'
extend "Interact", require './interact/mouse'
extend "Interact", require './interact/touch'

extend "Camera", require './camera/camera'

extend "Light", require './light/light'

extend "Material", require './material/material'
extend "Material", require './material/basic'
extend "Material", require './material/phong'
extend "Material", require './material/depth'

extend "Animation", require './animation/animation'


# _setupFrame - the accepted method for setting up onEachFrame in various browsers
# TODO - We should record the apps listening on this so we can pause individual ones?

PXL.applications = []

_setupFrame = (root) -> 


  if root.requestAnimationFrame
    onEachFrame = (context, run) -> 

      # Check to make sure we arent duplicating contexts and run funcs (due to restarting)
      for [c,r] in PXL.applications
        if c == context and r == run
          return

      PXL.applications.push [context,run]

      _cb = () ->
        for app in PXL.applications
          PXL.Context.switchContext app[0]
          app[1].call app[0]
        
        requestAnimationFrame _cb
      _cb()

  else if root.webkitRequestAnimationFrame
    onEachFrame = (context, run) -> 

      # Check to make sure we arent duplicating contexts and run funcs (due to restarting)
      for [c,r] in PXL.applications
        if c == context and r == run
          return

      PXL.applications.push [context,run]

      _cb = () ->
        for app in PXL.applications
          PXL.Context.switchContext app[0]
          app[1].call app[0]
        
        webkitRequestAnimationFrame _cb
      _cb()

  else if root.mozRequestAnimationFrame 
    onEachFrame = (context, run) ->

       PXL.applications.push [context,run]

      _cb = () ->
        for app in PXL.applications
          PXL.Context.switchContext app[0]
          app[1].call app[0] 
        mozRequestAnimationFrame _cb
      _cb()
  else
    onEachFrame = (context, run) ->
      PXL.applications.push [context,run]

      _go = () ->
        for app in PXL.applications
          PXL.Context.switchContext app[0]
          app[1].call app[0]

      setInterval _go, 1000 / 60

  root.onEachFrame = onEachFrame


if window?
  _setupFrame(window)

module.exports =
  PXL : PXL
  GL : GL
