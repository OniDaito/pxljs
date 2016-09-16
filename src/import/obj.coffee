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


- A class to import OBJ files

- TODO
  - We are passing in a queue here and this class modifies it
    - Do we want that, or should this class implement an interface of some kind? Not sure

- Potentially

// Check for the various File API support.
if (window.File && window.FileReader && window.FileList && window.Blob) {
  // Great success! All the File APIs are supported.
} else {
  alert('The File APIs are not fully supported in this browser.');
}  

###

{PXLWarning, PXLError, PXLLog} = require '../util/log'
{TriangleMesh, Triangle, Vertex} = require '../geometry/primitive'
{Vec3, Vec2} = require '../math/math'
{Node} = require '../core/node'
{RGB} = require '../colour/colour'
{Promise} = require '../util/promise'
{Request} = require '../util/request'
{PhongMaterial} = require '../material/phong'
{BasicColourMaterial} = require '../material/basic'

### OBJModel ###
# Load a basic OBJ Model as a set of nodes with materials

class OBJModel extends Node

  # **@constructor**
  # - **url** - a String - Required
  # - **promise** - a Promise 
  
  constructor: (@url, @promise) ->
    super()
    promise_main = new Promise()
    promise_material = new Promise()
    promise_data = new Promise()
  
    promise_main.when(promise_data).then () =>
      @promise.resolve()

    load_data_promise = () =>
      r = new Request(@url)
      r.get (data) =>
        
        # We assume that the material exists in the same place as the obj
        # TODO - allow setting the matlib path
        matlibName = @_checkForMaterials data
      
        if matlibName
          materials = {} # gets filled with materials when the promise completes
          load_material_promise = () =>

            matlibName = @url.substring(0,@url.lastIndexOf('/')) + "/" + matlibName
            
            # Always remember to set the correct context when we make
            # an asynchronous call 
            #PXL.Context.switchContext _cc
            
            r2 = new Request matlibName
            r2.get (matlibData) =>
              @_parseMaterialFile matlibData, materials, promise_material
      

          promise_material.then () =>
            @_parse data, materials
            promise_data.resolve()
          
          load_material_promise()
          
        else
          materials = []
          @_parse data, materials
          promise_data.resolve()

    load_data_promise()
                
    @

  # Check if this model file includes materials in a related material file

  _checkForMaterials: (text_data) ->
    lines = text_data.split("\n")
    for line in lines
      if line[0..5] == "mtllib"
        return line[7..]
    
      if line[0..1] == "f "
        break

    undefined

  # Parse the material file data.
  # So far, only basic phong materials are supported and RGB colours
  # callback is the function called when all the items have been loaded

  _parseMaterialFile : (text_data, materials, promise) ->
    lines = text_data.split("\n")

    # A temporary holder of promises for textures that need to be loaded
    # TODO - maybe a better way to do this?
    _tex_promises = []
    _tex_funcs = []
    _mat_names = []

    _material_promise = new Promise()

    # This function is called when materials are finally loaded - close over materials and promise
    _materialsLoaded = (_materials, _mat_names, _promise) ->

      return () ->
        # Go through all the materials and actually create them
        # The default shading for OBJ files is Phong Shading - this can be replaced by the user
        # if necessary before any draw calls (or after draw calls if you call shader automagic)
        for name in _mat_names
          m = _materials[name]
          if m.texture?
            _materials[name] = new PhongMaterial m.ambient, m.texture, m.specular, m.shine
          else
            _materials[name] = new PhongMaterial m.ambient, m.diffuse, m.specular, m.shine
     
        _promise.resolve()
  

    for line in lines
      if line[0..6] == "newmtl "
        mat_name = line.split(" ")[1]
        materials[mat_name] = {}
        _mat_names.push mat_name

      if line[0..1] == "Ka"
        tokens = line.split " "
        new_tokens = [parseFloat(token) for token in tokens[1..]][0]
        materials[mat_name].ambient = new RGB new_tokens[0],new_tokens[1],new_tokens[2]
      
      if line[0..1] == "Kd"
        tokens = line.split " "
        new_tokens = [parseFloat(token) for token in tokens[1..]][0]
        materials[mat_name].diffuse = new RGB new_tokens[0],new_tokens[1],new_tokens[2]

      if line[0..1] == "Ks"
        tokens = line.split " "
        new_tokens = [parseFloat(token) for token in tokens[1..]][0]
        materials[mat_name].specular = new RGB new_tokens[0],new_tokens[1],new_tokens[2]

      if line[0..1] == "Ns"
        tokens = line.split " "
        new_tokens = [parseInt(token) for token in tokens[1..]][0]
        materials[mat_name].shine = new_tokens[1]

      if line[0..6] == "map_Kd "
        tex_name = line[7..]
        
        # Again we assume textures are in the same place
        # TODO - Allow use of a texture path
        tex_url = @url.substring(0,@url.lastIndexOf('/')) + "/" + tex_name
        
        # Check in case we are testing or running with no webgl
        if PXL?
    
          # Go and load some textures - create a closure over data we need
         
          _tt = (_tex_url, _mat_name, _cc, _materials, _tex_promise)  ->
            return () ->
              PXL.Context.switchContext _cc
              PXL.GL.textureFromURL _tex_url, (tex) ->
                _materials[_mat_name].texture = tex
                _tex_promise.resolve()

          _tex_promise = new Promise()
          _tex_func = _tt tex_url, mat_name, PXL.Context, materials, _tex_promise

          _tex_promises.push _tex_promise
          _tex_funcs.push _tex_func
    
    # Now go through and see if we have any promises to resolve
    if _tex_promises.length > 0
      # Should auto resolve this promise?
      _ml = _materialsLoaded materials, _mat_names, promise
      _material_promise.when.apply(_material_promise, _tex_promises).then( _ml )
      for tf in _tex_funcs
        tf()
    else
      promise.resolve()
         
    @
  

  # Parse the data file completely, pulling in vertices
  # materials is an object passed in with actual materials under their name

  _parse: (text_data, materials) ->

    positions = []
    normals = []
    texcoords = []

    # Add the none material as a white, basic material

    materials["none"] = new BasicColourMaterial()

    # For each 'o' in the file, create a new node
    # and clear our arrays

    object_node = null
  
    # Offsets for vertices depending on objects
    # basically, the faces index does NOT get reset when
    # a new object occurs
    offset_v = 0
    offset_t = 0
    offset_n = 0

    # Could be heavy if the file is big :S
    lines = text_data.split("\n")

    for line in lines

      if line[0..1] == "o "
      
        object_node = new Node
        object_node._label = line[2..]
        @add object_node
    
        current_mesh = new TriangleMesh true
        object_node.geometry = current_mesh

        offset_v = positions.length
        offset_n = normals.length
        offset_t = texcoords.length

      if line[0..1] == "v "
        bits = line[2..].split " "
        tokens = (parseFloat(token) for token in bits)
        v = new Vec3 tokens[0], tokens[1], tokens[2]
        positions.push v

      else if line[0..2] == "vt "
        bits = line[3..].split " "
        tokens = (parseFloat(token) for token in bits)
        v = new Vec2 tokens[0], tokens[1]
        texcoords.push v

      else if line[0..2] == "vn "
        bits = line[3..].split " "
        tokens = (parseFloat(token) for token in bits)
        v = new Vec3 tokens[0], tokens[1], tokens[2]
        normals.push v

      else if line[0..6] == "usemtl "
        mat_name = line[7..]
        material = materials[mat_name]

        # I *believe* it is not possible for an OBJ *object* to have
        # more than one material
        if not object_node.material?
          object_node.material = material
        

      else if line[0..1] == "f "
        # Now we have faces we need to create. Good old indexes

        tc = line[2..]
        bits = tc.split " "
        bobs = ( bit.split("/") for bit in bits )


        if bobs.length == 3
          # We have a lovely triangle

          vertices = []
          for i in [0..2]
            idx_v = parseInt(bobs[i][0]) - 1
        
            p0 = positions[idx_v]
            v = new Vertex
              p : p0

            # normal lookup
            if bobs[i][2] != ""
              idx_n = parseInt(bobs[i][2]) - 1

              if idx_n < normals.length
                v.n = normals[idx_n].clone()

            # tex coord lookup
            if bobs[i][1] != ""
              idx_t = parseInt(bobs[i][1]) - 1
              if idx_t < texcoords.length
                v.t = texcoords[idx_t].clone()

            vertices.push v

          current_mesh.addTriangle new Triangle vertices[0], vertices[1], vertices[2]

        else if bobs.length == 4
          # we have a nasty quad - triangulate
          vertices = []
          for i in [0..3]
            idx_v = parseInt(bobs[i][0]) - 1
            p0 = positions[idx_v]
            
            v = new Vertex
              p : p0
            
            # normal lookup
            if bobs[i][2] != ""
              idx_n = parseInt(bobs[i][2]) - 1

              if idx_n < normals.length
                v.n = normals[idx_n].clone()
            
            # tex coord lookup
            if bobs[i][1] != ""
              idx_t = parseInt(bobs[i][1]) - 1
              if idx_t < texcoords.length
                v.t = texcoords[idx_t].clone()

            vertices.push v

          current_mesh.addTriangle new Triangle vertices[0], vertices[1], vertices[2]
          current_mesh.addTriangle new Triangle vertices[0], vertices[2], vertices[3]
          
        else
          # We have something like a triangle fan
  
          vertices = []
          for i in [0..bobs.length-1]
            idx_v = tokens[i] - 1
            p0 = positions[idx_v]

            v = new Vertex
              p : p0

            if bobs[i][2] != ""
              idx_n = parseInt(bobs[i][2]) - 1
              if idx_n < normals.length
                v.n = normals[idx_n]

            if bobs[i][1] != ""
              idx_t = parseInt(bobs[i][1]) - 1
              if idx_t < texcoords.length
                v.t = normals[idx_t]
                        
            vertices.push v

          for i in [1..tokens.length-1]
            if i == tokens.length-1
              current_mesh.addTriangle new Triangle vertices[0], vertices[i], vertices[1]
            else
              current_mesh.addTriangle new Triangle vertices[0], vertices[i], vertices[i+1]

    @

module.exports =
  OBJModel : OBJModel
