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

{Vec2,Edge2,Parabola} = require '../math/math'
{edge2Bisector} = require '../math/math_functions'

class MedialComponent 
  
  # Start and end are Vec2 points and the @component is either an edge or a 
  constructor : (@start, @end) ->
    @

class MedialComponentEdge extends MedialComponent
  constructor : (@edge) ->
    @

  # a value of 0 - 1 that samples between start and end 
  sample : (dt) ->
    dx = ((@end.x - @start.x) * dt) + @start.x
    @edge.sample(dx)


class MedialComponentParabola extends MedialComponent
  constructor : (@parabola) ->
    @

  sample : (dt) ->
    dx = ((@end.x - @start.x) * dt) + @start.x
    dy = ((@end.y - @start.y) * dt) + @start.y

    # Basically find the nearest y value to DY - not sure that is totally correct though :S
    [y0,y1] = @parabola.sample(dx)
    if y1 != y0
      if Math.abs(y0 - dy) < Math.abs(y1-dy)
        return y0
      else
        return y1
    y0

class MedialGraph

  constructor : ->
    @components = []
    @right_handed = true


  # Compute the voronoi graph for two joined edges
  voronoiEdgeEdge : (edge0, edge1) ->
    bisector = edge2Bisector edge0, edge1

    # As the bisector will only be for edges with angles less than 180, we can assume the shortest
    # edge is the one that will be crossed first
    # for now, we consider a
    short_edge  = edge1
    long_edge = edge0

    if edge0.length() < edge1.length()
      short_edge = edge0
      long_edge = edge1

    [knot_point, influence_point] = @edgeLineInfluence bisector, short_edge, @right_handed

    parta = new Edge2 bisector.start, knot_point

    @components.push new MedialComponentEdge parta

    [a,b,c] = long_edge.equation()

    # TODO - how do we know which parabola result to choose?
    parabola = new Parabola(influence_point,a,b,c) 

    cp = @edgeParabolaInfluence(parabola,long_edge,@right_handed)

    parabola

  # Function that determines where a parabola leaves the area of influence of an edge.
  # Takes the line in the form ax + by + c = 0

  edgeParabolaInfluence : (parabola, edge, right) ->

    [ea,eb,ec] = edge.equation()

    psa = eb
    psb = -ea
    psc = ea * edge.start.x + eb * edge.start.y + ec - eb * edge.start.x + ea * edge.start.y

    pea = eb
    peb = -ea
    pec = ea * edge.end.x + eb * edge.end.y + ec - eb * edge.end.x + ea * edge.end.y

    # two lines gives potentially 4 crossing points

    [s0,s1] = parabola.lineCrossing(psa,psb,psc)
    [e0,e1] = parabola.lineCrossing(pea,peb,pec)

    #console.log psa,psb,psc

    #console.log parabola.f, parabola.a, parabola.b, parabola.c

    console.log s0,s1
    console.log e0,e1

    spoints = [Vec2.normalize(s0), Vec2.normalize(s1)]
    epoints = [Vec2.normalize(e0), Vec2.normalize(e1)]

    tt = Vec2.normalize edge.start

    rp = []

    for point in spoints
      if right
        if tt.dot(point) > 0
          rp.push([point, edge.start])
      
      else if tt.dot(point) <= 0
          rp.push([point, edge.start])

    for point in epoints
      if right
        if tt.dot(point) > 0
          rp.push([point, edge.end])
      
      else if tt.dot(point) <= 0
          rp.push([point, edge.end])

    rp


  # Function that determines where a line equation leaves the area of influence of an edge
  # Takes the line in the form ax + by + c = 0

  edgeLineInfluence : (line,edge,right) ->
    # Get the equations of the lines perpendicular to edge, passing through the end points
    [ea,eb,ec] = edge.equation()

    [a,b,c] = line.equation()

    psa = eb
    psb = -ea
    psc = ea * edge.start.x + eb * edge.start.y + ec - eb * edge.start.x + ea * edge.start.y

    pea = eb
    peb = -ea
    pec = ea * edge.end.x + eb * edge.end.y + ec - eb * edge.end.x + ea * edge.end.y

    # find the intersection (hopefully they are not parallel lines :S )
    # We should have a determinate that is non-zero right?

    ys = (psa * c - psc * a) / (a * psb - psa * b)
    xs = (-b * ys - c) / a

    start_cross = new Vec2(xs,ys)

    ye = (pea * c - pec * a) / (a * peb - pea * b)
    xe = (-b * ye - c) / a

    end_cross = new Vec2(xe,ye)

    # We consider only one side of the edge, depending on whether left or right is true

    ts = Vec2.normalize start_cross
    tt = Vec2.normalize edge.start

    ts.normalize()
    tt.normalize()

    if right
      if tt.dot(ts) > 0
        return [end_cross, edge.end]
      else
        return [start_cross, edge.start]
    
    if tt.dot(ts) <= 0
      return [start_cross, edge.start]

    [end_cross, edge.end]

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
  MedialGraph : MedialGraph