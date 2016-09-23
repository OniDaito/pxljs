###
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


util = {}

util.extend = (obj, source) ->
  # ECMAScript5 compatibility based on: http://www.nczonline.net/blog/2012/12/11/are-your-mixins-ecmascript-5-compatible/
  if Object.keys
    keys = Object.keys(source)
    i = 0
    il = keys.length

    while i < il
      prop = keys[i]
      Object.defineProperty obj, prop, Object.getOwnPropertyDescriptor(source, prop)
      i++
  else
    safeHasOwnProperty = {}.hasOwnProperty
    for prop of source
      obj[prop] = source[prop]  if safeHasOwnProperty.call(source, prop)
  obj

# removes the element from the given list (if it exists) and returns the list
util.removeElement = (element, list) ->
  index = list.indexOf element
  list.splice index, 1 unless index is -1
  list

util.flatten = (obj) ->
  flat = []
  for key of obj
    flat.push obj[key]
  flat



util.type = (obj) ->
  if obj == undefined or obj == null
    return String obj
  classToType = new Object
  for name in "Boolean Number String Function Array Date"
    RegExp.split(" ")
  myClass = Object.prototype.toString.call obj
  if myClass of classToType
    return classToType(myClass)
  return 'object'


# TODO - ES5 has a clone method on Object. Should test for that

util.clone = (obj) ->

  # This line is supposed to be superfast but apparently doesnt 
  # clone completely, such as UniformLocations and similar
  
  JSON.parse JSON.stringify obj

  ###
  if not obj? or typeof obj isnt 'object'
    return obj

  if obj instanceof Date
    return new Date(obj.getTime()) 

  if obj instanceof RegExp
    flags = ''
    flags += 'g' if obj.global?
    flags += 'i' if obj.ignoreCase?
    flags += 'm' if obj.multiline?
    flags += 'y' if obj.sticky?
    return new RegExp(obj.source, flags) 

  # TODO - More typed array clones? 
  # we cant just call the constructor and set the classes you see! :S

  if obj instanceof Float32Array
    return new Float32Array(obj)

  if obj instanceof Uint16Array
    return new Uint16Array(obj)

  newInstance = new obj.constructor()

  for key of obj
    newInstance[key] = util.clone obj[key]

  return newInstance
  ###


# copy the values from one to another
# used to update the cache
# TODO - for now, lets not bother with objects inside object

util.copy = (from, to) ->

  if from instanceof Float32Array and to instanceof Float32Array
    if from.length == to.size
      for i in [0..from.length-1]
        to[i] = from[i]
      return


  if from instanceof Uint16Array and to instanceof Uint16Array
    if from.length == to.size
      for i in [0..from.length-1]
        to[i] = from[i]
      return
  
  if typeof from isnt 'object' and typof to isnt 'object'
    to = from
  

# Read the Parameters on the URL line in the browser
util.QueryString = () -> 

  query_string = {}
  query = window.location.search.substring(1) if window?
  vars = query.split("&")
  
  for i in [0..vars.length-1]
    pair = vars[i].split("=")
    
    if typeof query_string[pair[0]] == "undefined"
      query_string[pair[0]] = pair[1]

    else if typeof query_string[pair[0]] == "string"
      arr = [ query_string[pair[0]], pair[1] ]
      query_string[pair[0]] = arr
    
    else
      query_string[pair[0]].push(pair[1])
  
  return query_string

module.exports = util
