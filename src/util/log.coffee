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

Error Handling code

- TODO 
  * Line numbers maybe?
  * Problem with using @ as we are including this file in many places with node :S
  * Unfortunately, the way coffeescript works we have blablahblah = function() which means the functions dont have a name
    - therefore getting the function name for logging is HARD

###


cache = []

### Print Stack Trace funtion ###

printStackTrace = () ->
  callstack = []
  isCallstackPopulated = false

  try
    i.dont.exist+=0
  catch e
    if e.stack
      lines = e.stack.split('\n')

      for i in [0..lines.length-1]
    
        callstack.push(lines[i])
      
      callstack.shift()
      isCallstackPopulated = true

    else if window.opera and e.message
      lines = e.message.split('\n');

      for i in [0..lines.length-1]

        callstack.push(entry)
      
      callstack.shift()
      isCallstackPopulated = true
    

  if !isCallstackPopulated
    currentFunction = arguments.callee.caller
    while currentFunction
      fn = currentFunction.toString()
      fname = fn.substring(fn.indexOf("function") + 8, fn.indexOf('')) || 'anonymous'
      callstack.push(fname)
      currentFunction = currentFunction.caller

  callstack.join('\n')


printObjectName = (obj) ->
  funcNameRegex = /function (.{1,})\(/;
  results = (funcNameRegex).exec((obj).constructor.toString())
  if results?
    if results.length > 1
      return results[1]
  ""


### PXLError ###
# Thow an exception and print the message 
# - **msg** - a String
# - returns throws exception
PXLError  = (msg) =>
  f = "PXL Error : " + msg
  console.error (f)
  throw f

### PXLWarning ###
# Thow a warning and print the message 
# - **msg** - a String
# - returns this

PXLWarning  = (msg) =>
  f = "PXL Warning : " + msg
  
  console.warn (f)
  console.warn printStackTrace()
  @

### PXLWarningOnce ###
# Thow a warning only once and print the message 
# Potentially a warning shouldnt occur more than once ;)
# - **msg** - a String
# - returns this

PXLWarningOnce  = (msg) =>
  result = msg in cache
  if not result 
    f = "PXL Warning : " + msg
 
    console.warn (f)
    console.warn printStackTrace()
    cache.push msg
  @

### PXLDebug ###
# If in Debug print the message 
# - **msg** - a String
# - returns this

PXLDebug  = (msg) =>
  if PXL.Context.debug
    f = "PXL Debug : " + msg
    console.log (f)
  @

### PXLLog ###
# Log a message to the console
# - **msg** - a String
# - returns this
#
PXLLog  = (msg) ->
  f = "PXL Log : " + msg

  myName = arguments.callee.toString()
  myName = myName.substr('function '.length)
  myName = myName.substr(0, myName.indexOf('('))

  console.log (f)
  @

module.exports =
  PXLError : PXLError
  PXLWarning : PXLWarning
  PXLLog : PXLLog
  PXLWarningOnce : PXLWarningOnce
  PXLDebug : PXLDebug
