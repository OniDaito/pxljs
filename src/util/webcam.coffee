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

Webcam Access

###

{PXLWarning, PXLError} = require './log'

class WebCamRTC

  # Check we have the basic javascript in place
  hasGetUserMedia : () ->
    navigator.getUserMedia? or navigator.webkitGetUserMedia? or navigator.mozGetUserMedia? or navigator.msGetUserMedia?

  # Error callback function
  errorCallback : (user_callback) =>
    PXLWarning "Cannot create WebRTC video!"
    user_callback() if user_callback?
    @

  # constructor - Creates a webcamrtc instance with the following parameters
  #
  # dom_object_id (REQUIRED) : the dom id of the video object
  # width (OPTIONAL) : the minimum width of the camera
  # height (OPTIONAL) : the minimum height of the camera
  # grab_audio (OPTIONAL) : boolan - do we want the mic as well?

  constructor : (dom_object_id, width, height, grab_audio, on_error) ->
    
    video_params= {}
    video_params["video"] = true

    if width? or height?
      video_params["mandatory"] = {}
      video_params["mandatory"]["width"] = width if width?
      video_params["mandatory"]["height"] = height if height?


    if not @hasGetUserMedia
      PXLWarning "No support in this browser for WebRTC."
      on_error() if on_error?
      return

    navigator.getUserMedia = navigator.getUserMedia or navigator.webkitGetUserMedia or navigator.mozGetUserMedia or navigator.msGetUserMedia

    if not grab_audio?
      grab_audio = false

    video_params["audio"] = grab_audio

    @dom_object = document.getElementById dom_object_id

    error_handler = @errorCallback
    
    error_handler = on_error if on_error? 

    navigator.getUserMedia(video_params, (stream) =>
      @dom_object.src = window.URL.createObjectURL(stream)
    ,error_handler )

    @

'''
MediaStreamTrack.getSources(function(sourceInfos) {
  var audioSource = null;
  var videoSource = null;

  for (var i = 0; i != sourceInfos.length; ++i) {
    var sourceInfo = sourceInfos[i];
    if (sourceInfo.kind === 'audio') {
      console.log(sourceInfo.id, sourceInfo.label || 'microphone');

      audioSource = sourceInfo.id;
    } else if (sourceInfo.kind === 'video') {
      console.log(sourceInfo.id, sourceInfo.label || 'camera');

      videoSource = sourceInfo.id;
    } else {
      console.log('Some other kind of source: ', sourceInfo);
    }
  }

  sourceSelected(audioSource, videoSource);
});

function sourceSelected(audioSource, videoSource) {
  var constraints = {
    audio: {
      optional: [{sourceId: audioSource}]
    },
    video: {
      optional: [{sourceId: videoSource}]
    }
  };

  navigator.getUserMedia(constraints, successCallback, errorCallback);
}
'''

module.exports =
  WebCamRTC : WebCamRTC
