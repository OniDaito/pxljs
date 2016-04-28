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

The MD5 Model format written by ID Software for Doom3

http://www.3dgep.com/loading-and-animating-md5-models-with-opengl

###

{PXLWarning, PXLError, PXLLog} = require '../util/log'
{TriangleMesh, Triangle, Vertex} = require '../geometry/primitive'
{Vec4, Vec3, Vec2, Quaternion, Matrix4, Matrix3} = require '../math/math'
{Node} = require '../core/node'
{RGB, RGBA} = require '../colour/colour'
{Promise} = require '../util/promise'
{Request} = require '../util/request'
{PhongMaterial} = require '../material/phong'
{BasicColourMaterial} = require '../material/basic'
{Skeleton, Bone, Skin, SkinWeight, SkinIndex} = require '../animation/skeleton'

###MD5### 
# Loads an MD5 Model creating a set of nodes, materials and a skeleton
# MD5 is one of the widely used ID Software Model formats
# Regarding materials, for now we just load the nearest texture in the directory

class MD5Model extends Node

  # Basic constructor for OBJ
  # @url - the URL to the object in question
  # @promise (optional) - a promise that will be fulfilled when the code is loaded
  # TODO - We may wish to consider how this fits with queue and loading items :O
  # TODO - Remove the queue once its finished with?

  constructor : (@url, @promise, @params) ->
    super()
    @version = ""
    @num_joints = ""
    @num_meshes = ""

    @add new Skeleton() # as this is a node, it ends up added at the node level
    
    # Three promises, chained in order
    promise_textures = new Promise()
    promise_data = new Promise()
    promise_main = new Promise()

    # As Promise data is resolved after promise textures, we just have one here
    promise_main.when(promise_data).then () =>
      @promise.resolve()


    promise_textures.then (text_data) =>
      @_parse_data(text_data)
      promise_data.resolve() # Assuming parse_data never goes wrong :P

    load_data_promise = () =>
      r = new Request(@url)  
      r.get (data) =>
        @_parse_materials(data, promise_textures)
                    

    if @promise?
      # Create a set of promises
      load_data_promise()

    else
      # Make a synchronous get request
      onerror = (result) =>
        PXLError "Loading Model: " + url + " " + result

      r = new Request(@url)
      r.get( (data) =>
        @_parse_materials_sync(data)
        @_parse_data(data)
      ,onerror,true)

    @

  _computeW : (r0,r1,r2) ->
    t = 1.0 - (r0 * r0) - (r1 * r1) - (r2 * r2)
    if t < 0.0
      return 0.0
    t = -Math.sqrt(t)
    t


  _parse_materials_sync : (text_data) ->
    @


  # This function is tricky with all the promises it creates. It creates one master promise
  # and then several sub promises with get requests in order to go and load the various images
  # we need to create our materials.

  _parse_materials : (text_data, promise_textures) ->

    # Hunt fot any shader lines
    lines = text_data.split("\n");
    midx = 0

    base_path = @url[0..@url.lastIndexOf("/")-1]

    # Temporary, clean up later
    _material_promises = []
    @_material_by_name = {}
      
    for midx in [0..lines.length-1]
      line = lines[midx]

      if line.indexOf("shader") != -1
        lastquote = line.lastIndexOf('"')
        firstquote = line.indexOf('"')
        material_path = line[firstquote+1..lastquote-1]
        
        # Cheat a bit here - assuming there is a tga of the same name as the shader, for now
        # TODO  - Will need to change this sooner 
        material_url = base_path + "/" + material_path[material_path.lastIndexOf("/")+1..] + ".png"

        p = new Promise()
        _material_promises.push p
        
        # A closure with all the data we need to setup this material
        onsuccess_closure = () =>
          _p = p
          _material_path = material_path

          return (_texture) =>
            if PXL.Context.debug
              PXLLog "MD5Model Loaded a Texture: " + _material_path

            # default to phong with low specular
            # TODO Eventually we'll do this properly
            wh = new RGB.WHITE()
            spec = new RGB.BLACK() 
            @_material_by_name[_material_path] = new PhongMaterial wh, _texture, spec 
         
            _p.resolve()

        # Closure for when we cant load our texture - default to a white texture
        onerror_closure = () =>
          _p = p
          _material_path = material_path
          
          return (msg) =>
            # ignore and use a normal material
            if PXL.Context.debug
              PXLLog "MD5Model Failed to load a Texture: " + _material_path

            wh = new PXL.Colour.RGB 1.0,0.0,0.0
            @_material_by_name[_material_path] = new BasicColourMaterial wh

            _p.resolve()

        PXL.GL.textureFromURL material_url, onsuccess_closure(), onerror_closure()
                    
    # Grab all the textures we need - if they dont exist, replace with a 
    # white plain material for now. Eventually we'll check a material file
 
    promise_materials = new Promise()
    promise_materials.when.apply(promise_materials, _material_promises).then () =>        
      promise_textures.resolve(text_data)
  
    @

  _parse_data: (text_data) ->

    # Could be heavy if the file is big :S
    lines = text_data.split("\n");
    midx = 0

    # Create a temp joints array as we need to compute vertices with
    # them at the end of each mesh
  

    while midx < lines.length

      line = lines[midx]

      if line[0..9] == "MD5Version"
        @version = line[11..]

      if line[0..8] == "numJoints"
        @num_joints = parseInt(line[10..])

      if line[0..8] == "numMeshes"
        @num_meshes == parseInt(line[10..])

    
      # Start looping over the joints - the bones basically
      if line[0..7] == "joints {"
  
        for jidx in [0..@num_joints-1]

          jline = lines[midx + jidx + 1]

          lastquote = jline.lastIndexOf('"')
          name = jline[jline.indexOf('"')+1..lastquote-1]
          openbrace = jline.indexOf('(')
          closebrace = jline.indexOf(')')

          parent_idx = parseInt(jline[lastquote+1..openbrace-1])
          parent = undefined
          # I believe all parents are listed in MD5 before their children
          if parent_idx > -1 
            parent = @skeleton.getBone parent_idx

          tokens = jline[openbrace..closebrace].split(" ")
          p0 = parseFloat tokens[1]
          p1 = parseFloat tokens[2]
          p2 = parseFloat tokens[3]

          position = new Vec3(p0,p1,p2)

          openbrace = jline.lastIndexOf('(')
          closebrace = jline.lastIndexOf(')')

          tokens = jline[openbrace..closebrace].split(" ")
          r0 = parseFloat tokens[1]
          r1 = parseFloat tokens[2]
          r2 = parseFloat tokens[3]

          rotation = new Quaternion r0, r1, r2, @_computeW(r0,r1,r2)
          rotation.normalize()

          bone = new Bone name, jidx, parent, rotation, position
          
          @skeleton.addBone bone    
 
        midx += @num_joints

      # Now we actually create the seperate meshes (one material per mesh we suspect)
      # MD5 format calls the material a shader which is probably correct ;)
      # We ignore shader for now but this requires loading external files so thats
      # definitely a pre-parse step :S

      if line[0..5] == "mesh {"
        
        tline = lines[midx]

        # Find the mesh for this shader
        while tline.indexOf("shader") == -1
          midx += 1
          tline = lines[midx]

        material_path = tline[tline.indexOf('"')+1..tline.lastIndexOf('"')-1]


        while tline.indexOf("numverts") == -1
          midx +=1
          tline = lines[midx]

        num_verts = parseInt(tline[tline.indexOf("numverts")+8..] )

        # Create a subnode for our geometry and material

        current_mesh = new TriangleMesh true 
        current_node = new Node current_mesh

        # We should have all the materials by this point
        current_node.material =  @_material_by_name[material_path] if @_material_by_name?

        @add current_node 

        # Now loop over the verts, though these arent actual verts - they are indices
        # into the data really. First pair is the tex coords - second is the start index
        # the next is the count

        temp_verts = []
        
        for vidx in [0..num_verts-1]

          tline = lines[midx + vidx + 1]

          openbrace = tline.indexOf("(")
          closebrace = tline.indexOf(")")
          idx = parseInt(tline[tline.indexOf("vert")+1..openbrace-1])

          tokens = tline[openbrace..closebrace].split(" ")
          u = parseFloat tokens[1]
          v = parseFloat tokens[2]

          tokens = tline[closebrace..].split(" ")
          idx = parseInt tokens[1]
          count = parseInt tokens[2]

          temp_vert_struct = 
            u : new Vec2 u, v
            i : idx
            c : count

          temp_verts.push temp_vert_struct

        midx += num_verts
        

        # Now hunt for the number of triangles
        tline = lines[midx]
        while tline.indexOf("numtris") == -1
          midx +=1
          tline = lines[midx]

        num_tris = parseInt(tline[tline.indexOf("numtris")+7..])

        # Add enough indices for all the points
        for i in [0..(num_tris*3)-1]
          current_mesh.addIndex(0)

        tidx = 0
        
        for tidx in [0..num_tris-1]
          tline = lines[midx + tidx + 1]

          tri = tline.indexOf("tri")
          tokens = tline[tri..].split(" ")

          idx = parseInt tokens[1]
          a = parseInt tokens[2]
          b = parseInt tokens[3]
          c = parseInt tokens[4]

          # Consider the winding
          current_mesh.setIndex idx * 3, c
          current_mesh.setIndex idx * 3 + 1, b
          current_mesh.setIndex idx * 3 + 2, a

        midx += num_tris

        # Now hunt for the weights
        tline = lines[midx]
        while tline.indexOf("numweights") == -1
          midx +=1
          tline = lines[midx]

        num_weights = parseInt(tline[tline.indexOf("numweights")+10..])

        # Again we need a temporary weights array like temp verts etc
        temp_weights = []

        # Create a skin which we add to the current node
        current_skin = new Skin()
        
        for widx in [0..num_weights-1]
          tline = lines[midx + widx + 1]
          ws = tline.indexOf("weight")

          openbrace = tline.indexOf("(")
          closebrace = tline.indexOf(")")

          tokens = tline[ws..openbrace].split(" ")

          idx = parseInt tokens[1]
          bone_id = parseInt tokens[2]
          bias = parseFloat tokens[3]

          skinweight = new SkinWeight @skeleton.getBone(bone_id), bias 
          current_skin.addWeight skinweight

          tokens = tline[openbrace..closebrace].split(" ")

          p0 = parseFloat tokens[1]
          p1 = parseFloat tokens[2]
          p2 = parseFloat tokens[3]

          # Temporary weights array push - apparently for the GPU benefit
          temp_weights.push 
            position : new Vec3(p0,p1,p2)
            bias : bias
            bone : bone_id

        midx += num_weights

        # Now we process the current mesh from all the temporary crap we've made
        for i in [0..num_verts-1]

          # create skin indices
          si = new SkinIndex temp_verts[i].i, temp_verts[i].c
          current_skin.addIndex si

          # Now build the actual weights, chosen from the most biased
          # This places a limit on the number of weights passed in to the shader
          pos = new Vec3 0, 0, 0
          actual_weights = []

          for j in [0..si.count-1]
            actual_weights.push temp_weights[si.index + j]

          # Sort the weights keeping the most important ones
          _compare_weight = (a, b) ->
            return a.bias < b.bias

          actual_weights.sort(_compare_weight)

          if actual_weights.length > Skeleton.PXL_MAX_WEIGHTS
            actual_weights.splice Skeleton.PXL_MAX_WEIGHTS-1, actual_weights.length-1

          # Make sure all sum to 1.0
          total = 0
          for w in actual_weights
            total += w.bias

          total = 1.0 / total
          for w in actual_weights
            w.bias = w.bias * total
       
          # Now we actually create our vertices as the positions are created from
          # the bind pose of the skeleton and all the weights etc
        
          tw = []
          ti = []
      
          for j in [0..Skeleton.PXL_MAX_WEIGHTS-1]
            if j < actual_weights.length
              w = actual_weights[j]
          
              tw.push w.bias
              ti.push w.bone

              bp = w.position.clone()

              # So inverting here seems to work which it really shouldnt >< 
              # I suspect this may or may not work with the animaion file :S
              # Also, the rotation appears to be y and z reversed >< Not so good
              Quaternion.invert(@skeleton.getBone(w.bone).rotation_pose).transVec3 bp
              bp.add @skeleton.getBone(w.bone).position_pose
              bp.multScalar w.bias

              pos.add bp
 
            else
              tw.push 0
              ti.push 0


          # Create and add the actual first vertex, built from our bind pose
          vertex = new Vertex(
            p : pos
            t : temp_verts[i].u.clone()
            w : new Vec4 tw[0], tw[1], tw[2], tw[3]
            i : new Vec4 ti[0], ti[1], ti[2], ti[3]
            n : new Vec3 0, 0, 0
          )

          current_mesh.addVertex vertex

        # As we are using a trimesh, finally create our triangles and normals
        j = 0
        while j < current_mesh.indices.length
          p0 = current_mesh.vertices[current_mesh.indices[j]]
          p1 = current_mesh.vertices[current_mesh.indices[j+1]]
          p2 = current_mesh.vertices[current_mesh.indices[j+2]]
          triangle = new Triangle p0, p1, p2
          triangle.computeFaceNormal()

          p0.n.add triangle.n
          p1.n.add triangle.n
          p2.n.add triangle.n

          # We call push on faces directly as addTriangle builds up the 
          # indices table which we've already built. This is a bit naughty
          current_mesh.faces.push triangle
          j+=3

        for vertex in current_mesh.vertices
          vertex.n.normalize()

        current_node.add current_skin

      midx += 1

    # Delete any temporary things on this node
    @_material_by_name = undefined if @_material_by_name?

    @

   


module.exports = 
  MD5Model : MD5Model
