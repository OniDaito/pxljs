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

glValidEnumContexts = 

  # Generic setters and getters

  'enable': { 0:true }
  'disable': { 0:true }
  'getParameter': { 0:true }

  # Rendering

  'drawArrays': { 0:true }
  'drawElements': { 0:true, 2:true }

  # Shaders

  'createShader': { 0:true }
  'getShaderParameter': { 1:true }
  'getProgramParameter': { 1:true }

  # Vertex attributes

  'getVertexAttrib': { 1:true }
  'vertexAttribPointer': { 2:true }

  # Textures

  'bindTexture': { 0:true }
  'activeTexture': { 0:true }
  'getTexParameter': { 0:true, 1:true }
  'texParameterf': { 0:true, 1:true }
  'texParameteri': { 0:true, 1:true, 2:true }
  'texImage2D': { 0:true, 2:true, 6:true, 7:true }
  'texSubImage2D': { 0:true, 6:true, 7:true }
  'copyTexImage2D': { 0:true, 2:true }
  'copyTexSubImage2D': { 0:true }
  'generateMipmap': { 0:true }

  # Buffer objects

  'bindBuffer': { 0:true }
  'bufferData': { 0:true, 2:true }
  'bufferSubData': { 0:true }
  'getBufferParameter': { 0:true, 1:true }

  # Renderbuffers and framebuffers

  'pixelStorei': { 0:true, 1:true }
  'readPixels': { 4:true, 5:true }
  'bindRenderbuffer': { 0:true }
  'bindFramebuffer': { 0:true }
  'checkFramebufferStatus': { 0:true }
  'framebufferRenderbuffer': { 0:true, 1:true, 2:true }
  'framebufferTexture2D': { 0:true, 1:true, 2:true }
  'getFramebufferAttachmentParameter': { 0:true, 1:true, 2:true }
  'getRenderbufferParameter': { 0:true, 1:true }
  'renderbufferStorage': { 0:true, 1:true }

  # Frame buffer operations (clear, blend, depth test, stencil)

  'clear': { 0:true }
  'depthFunc': { 0:true }
  'blendFunc': { 0:true, 1:true }
  'blendFuncSeparate': { 0:true, 1:true, 2:true, 3:true }
  'blendEquation': { 0:true }
  'blendEquationSeparate': { 0:true, 1:true }
  'stencilFunc': { 0:true }
  'stencilFuncSeparate': { 0:true, 1:true }
  'stencilMaskSeparate': { 0:true }
  'stencilOp': { 0:true, 1:true, 2:true }
  'stencilOpSeparate': { 0:true, 1:true, 2:true, 3:true }

  # Culling

  'cullFace': { 0:true }
  'frontFace': { 0:true }


glEnums = null


initDebugContext = (ctx) ->
  if glEnums == null
    glEnums = { }
    for propertyName in ctx
      if typeof ctx[propertyName] == 'number'
        glEnums[ctx[propertyName]] = propertyName
      

mightBeEnum = (value) -> 
  glEnums[value] != undefined


glEnumToString = (value) ->
  checkInit()
  name = glEnums[value]
  (name != undefined) ? name :
      ("*UNKNOWN WebGL ENUM (0x" + value.toString(16) + ")")

glFunctionArgToString = (functionName, argumentIndex, value) ->
  funcInfo = glValidEnumContexts[functionName]
  if (funcInfo != undefined)
    if (funcInfo[argumentIndex])
      return glEnumToString(value)
    
  value.toString()


makeDebugContext = (ctx) ->
  initDebugContext(ctx)
