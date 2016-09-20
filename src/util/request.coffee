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

* http://coffeescriptcookbook.com/chapters/ajax/ajax_request_without_jquery

- TODO
  * Need to get some kind of percentage in here, along with a signal we can check!
  


- Potentially
- But what about not being in a browser, potentially? Nodejs style?

// Check for the various File API support.
if (window.File && window.FileReader && window.FileList && window.Blob) {
  // Great success! All the File APIs are supported.
} else {
  alert('The File APIs are not fully supported in this browser.');
}  


###

{Signal} = require './signal'
{PXLWarning, PXLError, PXLLog} = require './log'

### Request ###
# A class that makes an XMLHTTPRequest for us, given a url
# One important thing that request does is to hold the current
# GL context for us so that when loads complete, we can go back
# to our previous context
class Request

  # **@constructor**
  # - **url** - a String - Required
  constructor : (@url) ->
    # At the time of construction note down the WebGL context as we will need
    # that as the active context may have changed - async remember
    @_context = PXL.Context if PXL?

  # Decide how to parse the data we have
  _parse : (callback) ->

    # Doesnt seem to output any responses :(
    #PXLLog "Request Result of " + @url + " is " + @req.responseType, @
    l = @url.length - 1

    if @req.responseType == "" or @req.responseType == "text"
      # Basic DOM String - pass on
      callback(@req.responseText)

    else if @req.responseType == "json"
      data = eval '(' + @req.responseText + ')'
      data._coffeegl_request_url = @url # Add this because its really handy!
      callback(data)
    
    else if @req.responseType == "blob"
      PXLError "Blob Type not supported yet", @

    else if @req.responseType == ""
      PXLError "responseType was empty", @
    else
      # Just pass on the data
      callback(@req.responseText)

    @


  # **get** - Actually perform the request. Pass in a callback to handle the data
  # - **callback** - a Function
  # - **onerror** - a Function
  # - **synchronous** - a Boolean - Default false
  # - returns this

  get : (callback, onerror, synchronous=false) ->

    # Are we running in the browser? If so go with XMLHTTPRequest, else go with node's
    # readFile instead

    if XMLHttpRequest?

      @req = new XMLHttpRequest()

      if synchronous
        @req.open('GET', @url, false)
        @req.setRequestHeader('X-Requested-With', 'XMLHttpRequest')
        @req.send(null)
        @_parse(callback)

      else

        @req.onreadystatechange = () => 

          if @req.readyState is 4

            if @req.status is 200 or @req.status is 304   # Success result codes
              
              PXL.Context.switchContext @_context if PXL?
              @_parse(callback)

            else
              PXL.Context.switchContext @_context if PXL?
              onerror(@req.responseText)
        
        @req.open('GET', @url)
        @req.setRequestHeader('X-Requested-With', 'XMLHttpRequest')
        @req.send(null)

    else
      # Must be running on node (for tests etc)
      # We still provide the same interface however but we basically callback instantly
      # Issues may occur given this files location in the source tree :S

      fs = require('fs')
      
      if synchronous
        data = fs.readFileSync @url
        callback data.toString()

      else
        fs.readFile @url, (err, data) =>
          if err?
            PXLError "nodejs readFile Errored with " + err

          # TODO - should we really be doing a toString here? 
          callback data.toString()
      
    @

module.exports = 
  Request : Request
