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

A mesh is a collection of triangles with or without indices. All the triangles should have the same kinds of vertices 

- TODO
  * We split on materials at present. We should split on meshes if possible but
    not sure if the three.js supports that. For example, normal map and diffuse
    textures per mesh. Double check the three standard

  * There are texture loads in here. We need to set their callbacks and have a signal
    in here for when everything completes as 

  * is it a great idea to have an internal load queue
    - Probably not but we need to hook out to an external load queue so pass one in

ThreeJSModel is a node that creates geometries below it which are also nodes. These geometries are drawn seperatly, each with their own material. 
Accepts three.js style json model format

###


{Triangle, Quad, Vertex, TriangleMesh } = require '../geometry/primitive'
{Node} = require '../core/node'
{Vec2, Vec3, Vec4, Matrix4} = require '../math/math'
{PhongBasicMaterial} = require '../material/phong'
{RGB,RGBA} = require '../colour/colour'
{Texture} = require '../gl/texture'
{Request} = require '../util/request'
{Signal} = require '../util/signal'
{PXLWarning} = require '../util/log'
{Promise} = require '../util/promise'


###ThreeJSModel###
# ThreeJSModel accepts a json format of model (three.js version 3.1) and creates a set of nodes
# with a single top node, representing the model.

class ThreeJSModel extends Node

  _bitset: (value, position) ->
    return value & ( 1 << position );

  # Given data create the model
  # materials contain links to the textures they may or may not need
  # params is a dictionary of options we may wish to pass in such as
  # params.texturing = true/false - default = true
  # params.onLoad = called when the model is finally loaded
  # params.onItem = called when individual items are loaded

  constructor: (json_data, @params) ->
    super()
    
    if not @params?
      @params = {}
      @params.texturing = true

    else
      if not @params.texturing?
        @params.texturing = true
    

    @queue = new LoadQueue(@, @params.onItem, @params.onLoad)

    # We create one node per material - but each node shares all the buffers save
    # for the indices

    materials = json_data["materials"]

    if materials.length == 0
      @add(new Node(new TriangleMesh(true)))
    else

      for i in [0..materials.length-1]

        n = new Node()
        @add(n)

        n.dbgName = json_data["materials"][i]["DbgName"] if json_data["materials"][i]["DbgName"]?

        # TODO - DbgIndex == 1 - is that kosher?
        # TODO - defaulting to basic Phong Texture
        if json_data["materials"][i]["DbgName"] == "default" or  json_data["materials"][i]["DbgIndex"] == 1
          n.add PhongColourMaterial()
       
        else
          # Create a new material for this node
          colourAmbient = new RGB(json_data["materials"][i]["colorAmbient"][0],
            json_data["materials"][i]["colorAmbient"][1],
            json_data["materials"][i]["colorAmbient"][2])
          if not colourAmbient?
            colourAmbient = RGB.WHITE()

          colourDiffuse = new RGB(json_data["materials"][i]["colorDiffuse"][0],
            json_data["materials"][i]["colorDiffuse"][1],
            json_data["materials"][i]["colorDiffuse"][2])
          if not colourDiffuse?
            colourDiffuse = RGB.WHITE()

          colourSpecular = new RGB(json_data["materials"][i]["colorSpecular"][0],
            json_data["materials"][i]["colorSpecular"][1],
            json_data["materials"][i]["colorSpecular"][2])

          if not colourSpecular?
            colourSpecular = RGB.WHITE()

          specularCoef = json_data["materials"][i]["specularCoef"]

          if not json_data["materials"][i]["mapDiffuse"]?
            n.add(new PhongColourMaterial(colourAmbient, colourDiffuse, colourSpecular, specularCoef))
          
        n.geometry = new TriangleMesh(true)

        # Create a texture for this node if there is one

        if @params.texturing

          if json_data["materials"][i]["mapDiffuse"]? and json_data._coffeegl_request_url?
            # Exporting three.js in blender seems to give just the filename of the texture
            # So I pass it in here. We assume textures are in the same dir as the model file
            
            url = json_data._coffeegl_request_url.substring(0, json_data._coffeegl_request_url.lastIndexOf("/"));
            path =  url + "/" + json_data["materials"][i]["mapDiffuse"]
            cc = PXL.Context
        
            # Close over the variables at this point
      
            tf = new LoadItem do (n,path) ->
              _n = n
              _path = path
              _cc = cc           
              return () ->
                PXL.Context.switchContext _cc

                # Some heavy closures going on here! :P
                PXL.GL.textureFromURL(_path, (texture) => 
                  _n.add(new PhongBasicMaterial(texture, colourAmbient, colourDiffuse, colourSpecular, specularCoef))
                  @loaded()
                  @ 
                )
              
              @
              
            @queue.add tf
  

            
      #if @children.length > 1
      #  for i in [1..@children.length-1]
      #    @children[i].geometry.vertices = @children[0].geometry.vertices
   
    cc = PXL.Context
    model = @
    closure_parse  = do (n,model) ->
      data = json_data
      _model = model
      _cc = cc
      return () =>
        PXL.Context.switchContext _cc
        _model._parse(data)

    @queue.add new LoadItem () -> 
      closure_parse()
      @loaded()

    @queue.start()

  _parse : (json_data) =>

    node_idx = 0
   
    # create the vertices
    # Assume normals for all in these meshes as we seem to occasionally get missing ones
    vidx = 0
    vertices = []
    while vidx < json_data["vertices"].length
      vertices.push new Vertex
        p : new Vec3(json_data["vertices"][vidx++], json_data["vertices"][vidx++], json_data["vertices"][vidx++])

      #@children[0].geometry.addVertex new Vertex(new Vec3(json_data["vertices"][vidx++], json_data["vertices"][vidx++], json_data["vertices"][vidx++]),
      #undefined,
      #new Vec3(1.0,0.0,0.0))

    # We have to have matching colours if we havent been provided with any. At least for now. We can decorate with
    # a material class later perhaps?

    i = 0
    
    while i < json_data["faces"].length

      type = json_data["faces"][i++]

      prim

      # TODO - Move final vertex prim to the end once we have all the vertex data if possible
      # Quad or Triangle


      # TODO - Differing face types should result in differing geometry and nodes
      # - we need to check which material we have and whether or not we need another
      # node at all?

      # TODO - We assume that differing faces types are different materials - possibly not true

      vi0
      vi1
      vi2
      vi3
      midx = {id:0 , type: -1}

      if @_bitset(type,0)
        
        vi0 = json_data["faces"][i++]
        vi1 = json_data["faces"][i++]
        vi2 = json_data["faces"][i++]
        vi3 = json_data["faces"][i++]

        prim = new Quad(vertices[vi0], vertices[vi1], vertices[vi2], vertices[vi3])
        prim.indexed = true

      else
        vi0 = json_data["faces"][i++]
        vi1 = json_data["faces"][i++]
        vi2 = json_data["faces"][i++]

        prim = new Triangle(vertices[vi0], vertices[vi1], vertices[vi2])
        prim.indexed = true
        
      # Material
      if @_bitset(type,1)
        midx.id = json_data["faces"][i++]
        type2 = type | 1 # ignore quad or tris
        if midx.type == -1
          midx.type = type2
        else
          if type2 != midx.type
            PXLWarning "Different types within the same material"
        
      # Face UV
      if @_bitset(type,2)
        uvidx = json_data["faces"][i++]

      # Vertex UV
      # TODO - For some reason, UVS are held inside another array. Dunno why
      # hence the ["uvs"][0][i0] thing

      if @_bitset(type,3)
        i0 = json_data["faces"][i++]
        i1 = json_data["faces"][i++]
        i2 = json_data["faces"][i++]
        if prim instanceof Quad
          i3 = json_data["faces"][i++]
          vertices[vi3].t = new Vec2(json_data["uvs"][0][i3*2], json_data["uvs"][0][i3*2+1])
        
        vertices[vi0].t = new Vec2(json_data["uvs"][0][i0*2], json_data["uvs"][0][i0*2+1])
        vertices[vi1].t = new Vec2(json_data["uvs"][0][i1*2], json_data["uvs"][0][i1*2+1])
        vertices[vi2].t = new Vec2(json_data["uvs"][0][i2*2], json_data["uvs"][0][i2*2+1])


      # Face normal
      if @_bitset(type,4)
        nidx = json_data["faces"][i++]

      # Face Vertex Normals
      if @_bitset(type,5)
        i0 = json_data["faces"][i++]
        i1 = json_data["faces"][i++]
        i2 = json_data["faces"][i++]
        if prim instanceof Quad
          i3 = json_data["faces"][i++]
          vertices[vi3].n = new Vec3(json_data["normals"][i3*3], json_data["normals"][i3*3+1], json_data["normals"][i3*3+2])
        
        vertices[vi0].n = new Vec3(json_data["normals"][i0*3], json_data["normals"][i0*3+1], json_data["normals"][i0*3+2])
        vertices[vi1].n = new Vec3(json_data["normals"][i1*3], json_data["normals"][i1*3+1], json_data["normals"][i1*3+2])
        vertices[vi2].n = new Vec3(json_data["normals"][i2*3], json_data["normals"][i2*3+1], json_data["normals"][i2*3+2])

      # Face colour
      if @_bitset(type,6)
        cidx = json_data["faces"][i++]

      # Face Vertex Colours
      if @_bitset(type,7)
        i0 = json_data["faces"][i++]
        i1 = json_data["faces"][i++]
        i2 = json_data["faces"][i++]
        if prim instanceof Quad
          i3 = json_data["faces"][i++]

      if prim instanceof Triangle
        @children[midx.id].geometry.addTriangle(prim)
      else
        @children[midx.id].geometry.addQuad(prim)

    # remove any children with no geometry
    removals = []
    for child in @children
      if child.geometry?
        if child.geometry.vertices.length == 0
          removals.push child

    for child in removals
      @remove child

    @



module.exports = 
  ThreeJSModel : ThreeJSModel
