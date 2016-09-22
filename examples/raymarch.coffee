###
                       __  .__              ________ 
   ______ ____   _____/  |_|__| ____   ____/   __   \
  /  ___// __ \_/ ___\   __\  |/  _ \ /    \____    /
  \___ \\  ___/\  \___|  | |  (  <_> )   |  \ /    / 
 /____  >\___  >\___  >__| |__|\____/|___|  //____/  .co.uk
      \/     \/     \/                    \/         
                                              PXL
                                              Benjamin Blundell - ben@section9.co.uk
                                              http://www.section9.co.uk

This software is released under the MIT Licence. See LICENCE.txt for details

###

class RayMarchExample

  init : () ->
 
    q = new PXL.Geometry.Quad()

    q.vertices[0].c = new PXL.Colour.RGBA(1.0,0.0,0.0,1.0)
    q.vertices[1].c = new PXL.Colour.RGBA(0.0,1.0,0.0,1.0)
    q.vertices[2].c = new PXL.Colour.RGBA(0.0,0.0,1.0,1.0)

    # Pull in a custom shader
    r = new PXL.Util.Request('raymarch.glsl')
    r.get (data) =>
      @shader = PXL.GL.shaderFromText(data)
    
    @n0 = new PXL.Node q 
    @c = new PXL.Camera.OrthoCamera(new PXL.Math.Vec3(0,0,0.1))

    @n0.add @c
    @globaltime = 0

    # Mouse data
    @mp = new PXL.Math.Vec2(PXL.Context.width/2, PXL.Context.height/2)
    @ml = false
    @mr = false

    # Load a texture with our callback
    _tex_loaded = (texture) =>
      @t = texture
      @t.bind()

    PXL.GL.textureFromURL("/textures/chessboard.png", _tex_loaded, undefined, { unit: 0, wrapt: GL.REPEAT, wraps: GL.REPEAT })

    # Hook into the events for the mouse
    PXL.Context.mouseMove.add @onMouseMove, @
    PXL.Context.mouseDown.add @onMouseDown, @
    PXL.Context.mouseUp.add @onMouseUp, @

  onMouseMove : (event) ->
    @mp.x = event.mouseX
    @mp.y = event.mouseY

  onMouseUp : (event) ->
    if event.buttonLeft
      @ml = true 
    else
      @ml = false
   
    if event.buttonRight
      @mr = true 
    else
      @mr = false

  onMouseDown : (event) ->
    if event.buttonLeft
      @ml = true 
    else
      @ml = false
   
    if event.buttonRight
      @mr = true 
    else
      @mr = false

  draw : (dt) ->
    
    @globaltime += (dt/1000)
   
    GL.clearColor(0.15, 0.15, 0.15, 1.0)
    GL.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT)

    if @shader?
      @shader.bind()
      @shader.setUniform3v "uResolution", new PXL.Math.Vec3(PXL.Context.width, PXL.Context.height,0)
      @shader.setUniform1f "uGlobalTime", @globaltime
      @shader.setUniform1i "uChannel0", 0

      # xy coords, zw click (left right)
      vm = new PXL.Math.Vec4(@mp.x,@mp.y,0,0)
      if @ml
        vm.z = 1 
      if @mr
        vm.w = 1  
      @shader.setUniform4v "uMouse", vm

      dateObj= new Date()
      month = parseInt dateObj.getUTCMonth()
      day = parseInt dateObj.getUTCDate()
      year = parseInt dateObj.getUTCFullYear()
      time = dateObj.getTime() / 1000

      @shader.setUniform4v "uDate", new PXL.Math.Vec4(year,month,day,time)

      @n0.draw()
      
      @shader.unbind()


example = new RayMarchExample()

params = 
  canvas : 'webgl-canvas'
  context : example
  init : example.init
  draw : example.draw

cgl = new PXL.App params

