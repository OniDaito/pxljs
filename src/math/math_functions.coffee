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
# TODO - this file is sort of a catch all. Could do to be improved

###

{ Vec2, Vec3, Vec4, Matrix4, PI, EPSILON } = require '../math/math'
{ Vertex } = require '../geometry/primitive'

### rayPlaneIntersect ###
# Given 4 Vec3, work out the distance along line_dir where the intersection occurred

rayPlaneIntersect = (plane_point, plane_normal, line_point, line_dir) ->
  num = Vec3.dot(plane_normal, Vec3.sub(plane_point, line_point))
  den = Vec3.dot(plane_normal,line_dir)
  
  num/den


### screenNodeHitTest ###
# Given a node, camera & a point on the screen, traverse the hierarchy and find if anything was hit
# This works for brewed geometry only at present (though could work for normal as well im sure)
# Results are returned in ascending order of depth. Back facing and front facing triangles are included.


screenNodeHitTest = (sx,sy,camera,node) ->

  results = []
  _rec = (node, matrix) =>

    ray = camera.castRay(sx,sy)
   
    matrix = Matrix4.mult matrix, node.matrix

    if node.geometry?

      indexer = node.geometry.getTrisIndexer()
      num_tris = node.geometry.getNumTris()

      for i in [0..num_tris-1]

        [a,b,c] = indexer(i)

        # Flatten vertices and get their positions
        if a instanceof Vertex
          a = a.p
          b = b.p
          c = c.p

        # Some geometries may have degenerate triangles (tri-strip planes for example)
        # so quit early if any verts are the same
        if a.equals(b) or b.equals(c) or a.equals(c)
          continue

        # Transform into world space
        matrix.multVec(a).multVec(b).multVec(c)

        # Linear algebra barycentric approach
        # Real Time Rendering p581 / p750 (3rd ed)

        e1 = Vec3.sub b,a
        e2 = Vec3.sub c,a
        q = ray.xyz().cross e2
        alpha = e1.dot q

        if alpha > -EPSILON and alpha < EPSILON
          continue

        f = 1.0/alpha
        s = Vec3.sub camera.pos, a
        u = s.dot(q) * f
        
        if u < 0.0
          continue

        r = Vec3.cross s, e1
        v = ray.xyz().dot(r) * f
        
        if v < 0.0 or (u + v) > 1.0
          continue

        t = e2.dot(q) * f

        # TODO - t is the distance along the ray allegedly but it appears not to work :S

        ap = a.copy().multScalar(1-u-v)
        bp = b.copy().multScalar(u)
        cp = c.copy().multScalar(v)

        ap.add(bp).add(cp)

        dist = Vec3.sub(ap, camera.pos).length()

        results.push { "pos" : ap, "node" :  node, "index" : i, "dist" : dist}  
        
    # We need to continue with children as one may be infront of the other :P

    for child in node.children
      _rec child, matrix

  _rec(node, new Matrix4())

  _comp = (a,b) ->
    if a.dist < b.dist
      return -1
    if a.dist > b.dist
      return 1
    0

  results.sort(_comp)

  results

### precomputeTangent ###
# Given a face, compute the tangent at each vertex - A face being, in this case, 3 Vec3
# with 3 vertex normals and 3 texture co-ordinates of Vec2
# http://stackoverflow.com/questions/5255806/how-to-calculate-tangent-and-binormal


precomputeTangent = (a, b, c, na, nb, nc, ta, tb, tc) ->

  [_precomputeTangent(a, b, c, na, ta, tb, tc),
  _precomputeTangent(b, c, a, nb, tb, tc, ta),
  _precomputeTangent(c, a, b, nc, tc, ta, tb)]


_precomputeTangent = (a, b, c, n, ta, tb, tc) ->

  d = Vec3.sub b,a
  e = Vec3.sub c,a
  f = Vec2.sub tb, ta
  g = Vec2.sub tc, ta

  alpha = 1 / (( f.x * g.y ) - (f.y * g.x))

  tx = alpha * ( g.y * d.x  + -f.y * e.x )
  ty = alpha * ( g.y * d.y  + -f.y * e.y )
  tz = alpha * ( g.y * d.z  + -f.y * e.z )

  ux = alpha * ( -g.x * d.x +  f.x * e.x )
  uy = alpha * ( -g.x * d.y +  f.x * e.y )
  uz = alpha * ( -g.x * d.z +  f.x * e.z )

  tangent = new Vec3 tx,ty,tz
  binormal = new Vec3 ux,uy,uz

  # We could at this point, compute the whole matrix for this but we dont as 
  # this function is just for the tangent as a per vertex operation

  tangent = tangent.sub( Vec3.multScalar( n, Vec3.dot(n,tangent)))
  binormal2 = binormal.sub( Vec3.multScalar( n, Vec3.dot(n,binormal)))
  binormal2 = binormal2.sub( Vec3.multScalar( tangent, Vec3.dot(tangent,binormal)))

  tangent.normalize()
  binormal2.normalize()

  #new Matrix3(tangent, binormal2, n)
  # just the tangent for now, not the binormal or matrix
  tangent

### rayCircleIntersection ###
# http:#stackoverflow.com/questions/1073336/circle-line-collision-detection
# Given a ray and circle, solve the quadratic and find intersection points

rayCircleIntersection = (ray_start, ray_dir, circle_centre, circle_radius) ->

  f = PXL.Vec2.sub(ray_start,circle_centre)
  r = circle_radius

  a = ray_dir.dot( ray_dir )
  b = 2*f.dot( ray_dir )
  c = f.dot( f ) - r*r

  v = new PXL.Vec2()

  discriminant = b*b-4*a*c

  if discriminant != 0
    discriminant = Math.sqrt(discriminant)
    t1 = (-b - discriminant)/(2*a)
    t2 = (-b + discriminant)/(2*a)

    t = t2
    t = t1 if t2 < 0 

    # Plug back into our line equation
    
    v.copyFrom(ray_start)
    d2 = PXL.Vec2.multScalar(ray_dir,t)
    v.add(d2)

  v


# Scan through points producing an axis aligned bounding box
# Points are a list of Vec2/Vec3
boundingBox = (points) ->
  if points.length
    if points[0]._DIM == 3
      min = new PXL.Vec3(Infinity,Infinity,Infinity)
      max = new PXL.Vec3(-Infinity,-Infinity,-Infinity) 

      for point in points
        if point.x < min.x
          min.x = point.x
        if point.y < min.y
          min.y = point.y

        if point.x > max.x
          max.x = point.x

        if point.y > max.y
          max.y = point.y


    else if points[1]._DIM == 2
      min = new PXL.Vec2(Infinity,Infinity)
      max = new PXL.Vec2(-Infinity,-Infinity) 

      for point in points
        if point.x < min.x
          min.x = point.x
        if point.y < min.y
          min.y = point.y
        if point.z < min.z
          min.z = point.z

        if point.x > max.x
          max.x = point.x
        if point.y > max.y
          max.y = point.y
        if point.z > max.z
          max.z = point.z


  [min, max]


# Given two edges, get the perpendicular bisector between them
# This is represented by an edge and assumes that two edges share
# a common point. The edge is normalized
# It ignores the direction - it is only concerned with the join point.

edge2Bisector = (edge0, edge1) ->

  if edge0.start == edge1.start
    e0 = Vec2.normalize(Vec2.sub(edge0.end, edge0.start))
    e1 = Vec2.normalize(Vec2.sub(edge1.end, edge1.start))
    return new new Edge2(edge0.start, Vec2.add(edge0.start, Vec2.normalize(e0.add(e1))))

  else if edge0.end == edge1.start
    e0 = Vec2.normalize(Vec2.sub(edge0.start, edge0.end))
    e1 = Vec2.normalize(Vec2.sub(edge1.end, edge1.start))
    return new Edge2(edge0.end, Vec2.add(edge0.end, Vec2.normalize(e0.add(e1))))

  else if edge0.start == edge1.end
    e0 = Vec2.normalize(Vec2.sub(edge0.end, edge0.start))
    e1 = Vec2.normalize(Vec2.sub(edge1.start, edge1.end))
    return new Edge2(edge0.start, Vec2.add(edge0.start, Vec2.normalize(e0.add(e1))))

  else if edge0.end == edge1.end
    e0 = Vec2.normalize(Vec2.sub(edge0.start, edge0.end))
    e1 = Vec2.normalize(Vec2.sub(edge1.start, edge1.end))
    return new Edge2(edge0.end, Vec2.add(edge0.end,Vec2.normalize(e0.add(e1))))


  else
    PXLError "edge2Bisector - edges must have a common Vec2"
 
  

### LERP ###
# A simple function to map between two values returning a value between 0 and 1

lerp = (bottom,top,value) ->
  (value - bottom) / (top - bottom)

  
### closestPointLine ###
# Returns the closest point to a line.
# a - start of the line
# b - end of the line
# p - the point in question

closestPointLine = (a,b,p) ->

  # Cx to see the point is actually within limits
  dir = Vec2.sub b,a
  perp = new Vec3 dir.y, -dir.x, 0
  v0 = Vec3.sub new Vec3(b.x, b.y), new Vec3(a.x, a.y)
  v1 = Vec3.sub new Vec3(a.x, a.y), new Vec3(b.x, b.y)

  cross0 = Vec3.cross perp, v0
  cross1 = Vec3.cross perp, v1
  if cross0.z < 0
    return b
  else if cross1.z > 0
    return a

  # Cx for axis
  dir = Vec2.sub(b,a)
  if dir.x == 0
    return new Vec3 0,p.y
  if dir.y == 0
    return new Vec3 p.x, 0 
  
  # convert to y = mx + c form
  
  m = dir.y / dir.x
  c = a.y - (m * a.x)

  xp = (m * p.y + p.x - m*c) / (m*m + 1)
  yp = m*xp + c

  return new Vec2 xp,yp


    
### medialAxis2D ###
# Given a planar polygon (a list of 2D vertices), compute the the medial axis of the polygon
# as a set of pairs of 2D points (edges)

medialAxis2D = (polygon, top, left, bottom, right) ->

  # create pairs / edges
  if polygon.length < 3
    return []

  edges = []
  for idx in [0..polygon.length-1]
    if idx + 1 < polygon.length
      edges.push [ polygon[idx], polygon[idx+1] ]
    else
      edges.push [ polygon[idx], polygon[0] ]

  # find the chains - As we are going clockwise winding, inside is to the right of the vector
  # which is a positive cross product with z ( I think!)
  chains = []
  current_chain = new Array()

  for idx in [0..edges.length-1]
    
    e0 = edges[idx]
    e1 = edges[idx+1]
    
    if idx + 1 == edges.length
      e1 = edges[0]

    v0 = Vec3.sub new Vec3(e0[1].x, e0[1].y), new Vec3(e0[0].x, e0[0].y)
    v1 = Vec3.sub new Vec3(e1[1].x, e1[1].y), new Vec3(e1[0].x, e1[0].y)

    cross = Vec3.cross v0, v1

    if cross.z > 0
      # Its a reflex angle, therefore a chain
      
      if current_chain.length == 0
        current_chain.push e0
      
      current_chain.push [e1[0]] # push the reflex vertex too if chain is greater than one edge
      current_chain.push e1

      # there is an edge case here whereby the last edge could be in a chain already 
      # but I suspect that is rare and can be handled anyway

    else 
      # not a chain
      if current_chain.length == 0
        current_chain.push e0

      chains.push current_chain
      current_chain = new Array()

  voronoi = []
  wedges = []
  zaxis = new Vec3(0,0,1)
  wedge_length =100.0

  # we now have the chains so we must compute the voronoi diagram for each chain and combine
  for chain in chains
    for idx in [0..chain.length-1]

      # Wedges denote the area of effect for computing our initial bisectors.
      # They are internal and are denoted by a point and a direction vector.
      # Each element has two lines that denote a wedge and we want to be inside them

      element = chain[idx]
      wedge = []
      # compute the initial voronoi graph. The wedges for each element
      if element.length == 2 
        # its an edge so two lines perpendicular
        v0 = Vec3.sub new Vec3(element[0].x, element[0].y), new Vec3(element[1].x, element[1].y)
        cross = Vec3.cross v0, zaxis
        cross.normalize()

        wedge.push [new Vec2(element[0].x, element[0].y), new Vec2(element[0].x - cross.x, element[0].y - cross.y)]
        wedge.push [new Vec2(element[1].x, element[1].y), new Vec2(element[1].x - cross.x, element[1].y - cross.y)]

       
      else
        # Its a reflex point so two lines perpendicular to the edges that join it
        p = idx - 1
        if idx == 0
          p = chain.length - 1

        n = idx + 1
        if idx == chain.length - 1
          n = 0

        pe = chain[p]
        ne = chain[n]


        v0 = Vec3.sub new Vec3(pe[0].x, pe[0].y), new Vec3(pe[1].x, pe[1].y)
        cross = Vec3.cross v0, zaxis
        cross.normalize()
        wedge.push [new Vec2(element[0].x, element[0].y),  new Vec2(element[0].x - cross.x, element[0].y - cross.y)]

        v1 = Vec3.sub new Vec3(ne[0].x, ne[0].y), new Vec3(ne[1].x, ne[1].y)
        cross = Vec3.cross v1, zaxis
        cross.normalize()
        wedge.push [ new Vec2(element[0].x, element[0].y),  new Vec2(element[0].x - cross.x, element[0].y - cross.y)]
        
      wedges.push wedge

  console.log wedges

  # For now, compute the voronoi for two chains


  return wedges


module.exports = 
  rayPlaneIntersect : rayPlaneIntersect
  rayCircleIntersection : rayCircleIntersection
  precomputeTangent : precomputeTangent
  closestPointLine : closestPointLine
  medialAxis2D : medialAxis2D
  boundingBox : boundingBox
  edge2Bisector : edge2Bisector
  screenNodeHitTest : screenNodeHitTest
