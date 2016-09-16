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


Previously we had queues and load items here but it seemed better to just use promises
somewhat more intelligently. At some point we'll need to figure out filesizes and such from
our requests which is not always possible

http://blogs.msdn.com/b/ie/archive/2011/09/11/asynchronous-programming-in-javascript-with-promises.aspx
https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects

###

{PXLWarning, PXLError, PXLLog} = require '../util/log'


### Promise ###
# A class to handle the loading of many items asynchronously
# Promises seem popular but I thought I'd include one anyway as its good
# to learn and its not in all browsers. This one presents the results in
# the order in which the promises are passed (handy). Also, the when function
# doesnt queue - things fire and return whenever.
# These promises also record the context for WebGL if it exists

class Promise
  # **@constructor**
  constructor : () ->
    @context = PXL.Context if PXL?
    @

  # **when**
  # when takes any number of promises. When it's promises are resolved
  # this promise then becomes resolved. The function returns the parameters
  # in the same order the promises were passed in
  # TODO = There is potential that a particularly fast function will return 
  # before all this resolved as the function has already started in order to 
  # return its promise
  # - **arguments** - a variable number of arguments of type Promise
  # - returns this

  when : () ->
    
    @results = [0..arguments.length-1] # Place holders
    @count = arguments.length

    failure = () =>
      @reject arguments

    for fidx in [0..arguments.length-1]

      promise = arguments[fidx]
      
      # Create a c

      success_closure = (top_promise, position) ->
        _top_promise = top_promise
        _position = position
       
        success = (value) ->
          PXL.Context.switchContext _top_promise.context if _top_promise.context?
          _top_promise.results[_position] = value
          _top_promise.count -= 1
          if _top_promise.count == 0
            # Skip going through resolve on this one :P
            _top_promise.onResolved.apply(_top_promise,_top_promise.results) 

        success

      promise.then(success_closure(@,fidx), failure)
    @

  # **then**
  # - **onResolved** - a Function 
  # - **onRejected** - a Function
  # - returns this
  then : (@onResolved, @onRejected) ->
    PXL.Context.switchContext @context if @context?
    @
 
  # **resolve**
  # - **value** - any data to be passed to onResolved 
  resolve : (value) ->
    PXL.Context.switchContext @context if @context?
    @onResolved value if @onResolved?
  
  # **reject**
  # - **value** - any data to be passed to onRejected
  reject : (value) ->
    PXL.Context.switchContext @context if @context?
    @onRejected value if @onRejected?


module.exports =
  Promise : Promise
