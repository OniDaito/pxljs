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

An implementation of Fortune's Sweep algorithm based on the C++ Implementation from 
http:#skynet.ie/~sos/mapviewer/voronoi.php and the Javascript Implementation found
at https:#github.com/gorhill/Javascript-Voronoi/blob/master/rhill-voronoi-core.js

Adpated from the excellent work by Raymond Hill 

Copyright (C) 2010-2013 Raymond Hill https://github.com/gorhill/Javascript-Voronoi

Licensed under The MIT License http://en.wikipedia.org/wiki/MIT_License

Permission is hereby granted, free of charge, to any person obtaining a copy of this
software and associated documentation files (the "Software"), to deal in the Software 
without restriction, including without limitation the rights to use, copy, modify, merge, 
publish, distribute, sublicense, and/or sell copies of the Software, and to permit 
persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR 
PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE 
FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR 
OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
DEALINGS IN THE SOFTWARE.

###

{Vec2,Vec3,Edge2} = require '../math/math'
{RedBlackTree} = require './red_black_tree'


# TODO - Sort out this edge as we have this in math as well

class Edge
  constructor: (@lSite, @rSite) ->
    @va = @vb = null

# Site Methods

class Cell
  constructor : (@site) ->
    @halfedges = []
    @closeMe = false

  init : (@site) ->
    @halfedges = []
    @closeMe = false
    @


  prepareHalfedges : () ->
    halfedges = @halfedges
    iHalfedge = halfedges.length
    edge
    # get rid of unused halfedges
    # rhill 2011-05-27: Keep it simple, no point here in trying
    # to be fancy: dangling edges are a typically a minority.
    
    while iHalfedge--
      edge = halfedges[iHalfedge].edge
      if (!edge.vb or !edge.va)
        halfedges.splice(iHalfedge,1)
  

    # rhill 2011-05-26: I tried to use a binary search at insertion
    # time to keep the array sorted on-the-fly (in Cell.addHalfedge()).
    # There was no real benefits in doing so, performance on
    # Firefox 3.6 was improved marginally, while performance on
    # Opera 11 was penalized marginally.
    halfedges.sort( (a,b) -> 
        return b.angle-a.angle
    )
    return halfedges.length


  # Return a list of the neighbor Ids
  getNeighborIds : () ->
    neighbors = []
    iHalfedge = @halfedges.length
    edge
    
    while iHalfedge--
      edge = @halfedges[iHalfedge].edge
      if edge.lSite isnt null and edge.lSite.voronoiId != @site.voronoiId
        neighbors.push(edge.lSite.voronoiId)
    
      else if edge.rSite isnt null and edge.rSite.voronoiId != @site.voronoiId
        neighbors.push(edge.rSite.voronoiId)
          
    return neighbors

# Compute bounding box
#
  getBbox : () ->
    halfedges = @halfedges
    iHalfedge = halfedges.length
    xmin = Infinity
    ymin = Infinity
    xmax = -Infinity
    ymax = -Infinity
    v
    vx
    vy

    while iHalfedge--
      v = halfedges[iHalfedge].getStartpoint()
      vx = v.x
      vy = v.y
      if vx < xmin 
        xmin = vx
      
      if vy < ymin
        ymin = vy
      
      if vx > xmax
        xmax = vx
      
      if vy > ymax
        ymax = vy
      # we dont need to take into account end point,
      # since each end point matches a start point
    
      rval =
        x: xmin
        y: ymin
        width: xmax-xmin
        height: ymax-ymin
      
      return rval

  # Return whether a point is inside, on, or outside the cell:
  #   -1: point is outside the perimeter of the cell
  #    0: point is on the perimeter of the cell
  #    1: point is inside the perimeter of the cell
  #
  pointIntersection : (x, y) ->
    # Check if point in polygon. Since all polygons of a Voronoi
    # diagram are convex, then:
    # http:#paulbourke.net/geometry/polygonmesh/
    # Solution 3 (2D):
    #   "If the polygon is convex then one can consider the polygon
    #   "as a 'path' from the first vertex. A point is on the interior
    #   "of this polygons if it is always on the same side of all the
    #   "line segments making up the path. ...
    #   "(y - y0) (x1 - x0) - (x - x0) (y1 - y0)
    #   "if it is less than 0 then P is to the right of the line segment,
    #   "if greater than 0 it is to the left, if equal to 0 then it lies
    #   "on the line segment"
    
    halfedges = @halfedges
    iHalfedge = halfedges.length
    halfedge
    p0
    p1
    r
    
    while iHalfedge--
      halfedge = halfedges[iHalfedge]
      p0 = halfedge.getStartpoint()
      p1 = halfedge.getEndpoint()
      
      r = (y-p0.y)*(p1.x-p0.x)-(x-p0.x)*(p1.y-p0.y)
      
      if !r
        return 0
    
      if r > 0
        return -1

    return 1

# Could export this properly, along with edge and half-edge as useful things more generally?
class Diagram

  constructor: (@site) ->
    @


  
class Halfedge

  constructor : (@edge, lSite, rSite) ->
    @site = lSite

    # 'angle' is a value to be used for properly sorting the
    # halfsegments counterclockwise. By convention, we will
    # use the angle of the line defined by the 'site to the left'
    # to the 'site to the right'.
    # However, border edges have no 'site to the right': thus we
    # use the angle of line perpendicular to the halfsegment (the
    # edge should have both end points defined in such case.)
    if (rSite)
      @angle = Math.atan2(rSite.y-lSite.y, rSite.x-lSite.x)
    
    else
      va = edge.va
      vb = edge.vb
      # rhill 2011-05-31: used to call getStartpoint()/getEndpoint(),
      # but for performance purpose, these are expanded in place here.
      if edge.lSite is lSite 
        @angle = Math.atan2(vb.x-va.x, va.y-vb.y) 
      else
        Math.atan2(va.x-vb.x, vb.y-va.y)

  getStartpoint : () ->
    if @edge.lSite is @site
      return @edge.va 
    return @edge.vb

  getEndpoint : () ->
    if @edge.lSite is @site
      return @edge.vb
    return @edge.va


# rhill 2011-06-07: For some reasons, performance suffers significantly
# when instanciating a literal object instead of an empty ctor
# I have ignored this for now

class Beachsection
  constructor : () ->
    @



# ---------------------------------------------------------------------------
# Circle event methods

# rhill 2011-06-07: For some reasons, performance suffers significantly
# when instanciating a literal object instead of an empty ctor
  
class CircleEvent

  constructor : () ->
    # rhill 2013-10-12: it helps to state exactly what we are at ctor time.
    @arc = null
    @rbLeft = null
    @rbNext = null
    @rbParent = null
    @rbPrevious = null
    @rbRed = false
    @rbRight = null
    @site = null
    @x = @y = @ycenter = 0
    


class Voronoi

  constructor : () ->
    @vertices = null
    @edges = null
    @cells = null
    @toRecycle = null
    @beachsectionJunkyard = []
    @circleEventJunkyard = []
    @vertexJunkyard = []
    @edgeJunkyard = []
    @cellJunkyard = []

  @abs : Math.abs
  @epsilon :  1e-9
  @invepsilon = 1.0 / @epsilon

  equalWithEpsilon : (a,b) ->
    Math.abs(a-b) < 1e-9 
  
  greaterThanWithEpsilon : (a,b) ->
    a-b>1e-9
  
  greaterThanOrEqualWithEpsilon : (a,b) -> 
    b-a<1e-9
  
  lessThanWithEpsilon : (a,b) -> 
    b-a>1e-9
  
  lessThanOrEqualWithEpsilon : (a,b) -> 
    a-b<1e-9

  createHalfedge : (edge, lSite, rSite) ->
    new Halfedge(edge, lSite, rSite)


  reset : () ->
    if !@beachline
      @beachline = new RedBlackTree()

    # Move leftover beachsections to the beachsection junkyard.
    if @beachline.root
      beachsection = @beachline.getFirst(@beachline.root)
      while beachsection
        @beachsectionJunkyard.push(beachsection) # mark for reuse
        beachsection = beachsection.rbNext
            
    @beachline.root = null
    if !@circleEvents
      @circleEvents = new RedBlackTree()
    
    @circleEvents.root = @firstCircleEvent = null
    @vertices = []
    @edges = []
    @cells = []
    @segments = [] # New Oni Addition

  # this create and add a vertex to the internal collection

  createVertex : (x, y) ->
    v = @vertexJunkyard.pop()
    if !v 
      v = new Vec2(x, y)
    else
      v.x = x
      v.y = y
  
    @vertices.push(v)
    v

  # this create and add an edge to internal collection, and also create
  # two halfedges which are added to each site's counterclockwise array
  # of halfedges.

  createEdge : (lSite, rSite, va, vb) ->
    edge = @edgeJunkyard.pop()
    if !edge
      edge = new Edge(lSite, rSite)

    else
      edge.lSite = lSite
      edge.rSite = rSite
      edge.va = edge.vb = null

    @edges.push edge
    if va
      @setEdgeStartpoint(edge, lSite, rSite, va)
    
    if vb
      @setEdgeEndpoint(edge, lSite, rSite, vb)
  
    @cells[lSite.voronoiId].halfedges.push(@createHalfedge(edge, lSite, rSite))
    @cells[rSite.voronoiId].halfedges.push(@createHalfedge(edge, rSite, lSite))
    
    edge
  

  createBorderEdge : (lSite, va, vb) ->
    edge = @edgeJunkyard.pop()
    
    if !edge
      edge = new Edge(lSite, null)
    else
      edge.lSite = lSite
      edge.rSite = null
    
    edge.va = va
    edge.vb = vb
    @edges.push(edge)
    edge


  setEdgeStartpoint : (edge, lSite, rSite, vertex) ->
    if !edge.va and !edge.vb
      edge.va = vertex
      edge.lSite = lSite
      edge.rSite = rSite
  
    else if edge.lSite is rSite
      edge.vb = vertex
        
    else
      edge.va = vertex
    

  setEdgeEndpoint : (edge, lSite, rSite, vertex) ->
    @setEdgeStartpoint(edge, rSite, lSite, vertex)



  createCell : (site) ->
    cell = @cellJunkyard.pop()
    if cell 
      return cell.init(site)
    
    new Cell(site)

  createBeachsection : (site) ->
    beachsection = @beachsectionJunkyard.pop()
    if !beachsection
      beachsection = new Beachsection()
  
    beachsection.site = site
    beachsection

  # calculate the left break point of a particular beach section,
  # given a particular sweep line
  leftBreakPoint : (arc, directrix) ->
    # http:#en.wikipedia.org/wiki/Parabola
    # http:#en.wikipedia.org/wiki/Quadratic_equation
    # h1 = x1,
    # k1 = (y1+directrix)/2,
    # h2 = x2,
    # k2 = (y2+directrix)/2,
    # p1 = k1-directrix,
    # a1 = 1/(4*p1),
    # b1 = -h1/(2*p1),
    # c1 = h1*h1/(4*p1)+k1,
    # p2 = k2-directrix,
    # a2 = 1/(4*p2),
    # b2 = -h2/(2*p2),
    # c2 = h2*h2/(4*p2)+k2,
    # x = (-(b2-b1) + Math.sqrt((b2-b1)*(b2-b1) - 4*(a2-a1)*(c2-c1))) / (2*(a2-a1))
    # When x1 become the x-origin:
    # h1 = 0,
    # k1 = (y1+directrix)/2,
    # h2 = x2-x1,
    # k2 = (y2+directrix)/2,
    # p1 = k1-directrix,
    # a1 = 1/(4*p1),
    # b1 = 0,
    # c1 = k1,
    # p2 = k2-directrix,
    # a2 = 1/(4*p2),
    # b2 = -h2/(2*p2),
    # c2 = h2*h2/(4*p2)+k2,
    # x = (-b2 + Math.sqrt(b2*b2 - 4*(a2-a1)*(c2-k1))) / (2*(a2-a1)) + x1

    # change code below at your own risk: care has been taken to
    # reduce errors due to computers' finite arithmetic precision.
    # Maybe can still be improved, will see if any more of this
    # kind of errors pop up again.
    site = arc.site
    rfocx = arc.site.x
    rfocy = arc.site.y
    pby2 = rfocy-directrix

    # parabola in degenerate case where focus is on directrix
    if !pby2
      return rfocx
  
    lArc = arc.rbPrevious
    
    if !lArc
      return -Infinity
  
    site = lArc.site
    lfocx = site.x
    lfocy = site.y
    plby2 = lfocy-directrix
    
    # parabola in degenerate case where focus is on directrix
    if !plby2
      return lfocx
  
    # We have the site to the left of this site (lfoc) and the site itself (rfoc)

    hl = lfocx-rfocx
    aby2 = 1/pby2-1/plby2
    b = hl/plby2
    
    # This is where the two parabolas cross it seems :S We return the X co-ordinate
    if aby2
      return (-b+Math.sqrt(b*b-2*aby2*(hl*hl/(-2*plby2)-lfocy+plby2/2+rfocy-pby2/2)))/aby2+rfocx
    
    # both parabolas have same distance to directrix, thus break point is midway
    (rfocx+lfocx)/2
  

# calculate the right break point of a particular beach section,
# given a particular directrix
  rightBreakPoint : (arc, directrix) ->
    rArc = arc.rbNext
    if rArc
      return @leftBreakPoint(rArc, directrix)
  
    site = arc.site
    if site.y == directrix  # could be ===/ is here
      return site.x

    Infinity
    

  detachBeachsection : (beachsection) ->
    @detachCircleEvent(beachsection) # detach potentially attached circle event
    @beachline.removeNode(beachsection) # remove from RB-tree
    @beachsectionJunkyard.push(beachsection) # mark for reuse
  

  removeBeachsection : (beachsection) ->
    circle = beachsection.circleEvent
    x = circle.x
    y = circle.ycenter
    vertex = @createVertex x,y
    previous = beachsection.rbPrevious
    next = beachsection.rbNext
    disappearingTransitions = [beachsection]
    abs_fn = Math.abs

    # remove collapsed beachsection from beachline
    @detachBeachsection(beachsection)

    # there could be more than one empty arc at the deletion point, this
    # happens when more than two edges are linked by the same vertex,
    # so we will collect all those edges by looking up both sides of
    # the deletion point.
    # by the way, there is *always* a predecessor/successor to any collapsed
    # beach section, it's just impossible to have a collapsing first/last
    # beach sections on the beachline, since they obviously are unconstrained
    # on their left/right side.

    # look left
    lArc = previous
    while (lArc.circleEvent and abs_fn(x-lArc.circleEvent.x) < 1e-9) and abs_fn(y-lArc.circleEvent.ycenter) < 1e-9
      previous = lArc.rbPrevious
      disappearingTransitions.unshift(lArc)
      @detachBeachsection(lArc) # mark for reuse
      lArc = previous
  
    # even though it is not disappearing, I will also add the beach section
    # immediately to the left of the left-most collapsed beach section, for
    # convenience, since we need to refer to it later as this beach section
    # is the 'left' site of an edge for which a start point is set.
    disappearingTransitions.unshift(lArc)
    @detachCircleEvent(lArc)

    # look right
    rArc = next
    while (rArc.circleEvent and abs_fn(x-rArc.circleEvent.x) < 1e-9) and abs_fn(y-rArc.circleEvent.ycenter)<1e-9
      next = rArc.rbNext
      disappearingTransitions.push(rArc)
      @detachBeachsection(rArc) # mark for reuse
      rArc = next

    # we also have to add the beach section immediately to the right of the
    # right-most collapsed beach section, since there is also a disappearing
    # transition representing an edge's start point on its left.
    disappearingTransitions.push(rArc)
    @detachCircleEvent(rArc)

    # walk through all the disappearing transitions between beach sections and
    # set the start point of their (implied) edge.
    nArcs = disappearingTransitions.length
    iArc

    for iArc in [1..nArcs-1]
      rArc = disappearingTransitions[iArc]
      lArc = disappearingTransitions[iArc-1]
      @setEdgeStartpoint(rArc.edge, lArc.site, rArc.site, vertex)

    # create a new edge as we have now a new transition between
    # two beach sections which were previously not adjacent.
    # since this edge appears as a new vertex is defined, the vertex
    # actually define an end point of the edge (relative to the site
    # on the left)
    lArc = disappearingTransitions[0]
    rArc = disappearingTransitions[nArcs-1]
    rArc.edge = @createEdge(lArc.site, rArc.site, undefined, vertex)

    # create circle events if any for beach sections left in the beachline
    # adjacent to collapsed sections
    @attachCircleEvent(lArc)
    @attachCircleEvent(rArc)

  addBeachsection : (site) ->
    x = site.x
    directrix = site.y

    # find the left and right beach sections which will surround the newly
    # created beach section.
    # rhill 2011-06-01: This loop is one of the most often executed,
    # hence we expand in-place the comparison-against-epsilon calls.
    lArc
    rArc
    dxl
    dxr
    node = @beachline.root

    while node
      dxl = @leftBreakPoint(node,directrix)-x
      # x lessThanWithEpsilon xl => falls somewhere before the left edge of the beachsection
      if dxl > 1e-9
        # this case should never happen
        # if (!node.rbLeft) ->
        #    rArc = node.rbLeft
        #    break
        #    }
        node = node.rbLeft
        
      else 
        dxr = x-@rightBreakPoint(node,directrix)
        # x greaterThanWithEpsilon xr => falls somewhere after the right edge of the beachsection
        if dxr > 1e-9
          if !node.rbRight
            lArc = node
            break
    
          node = node.rbRight
    
        else 
          # x equalWithEpsilon xl => falls exactly on the left edge of the beachsection
          if dxl > -1e-9
            lArc = node.rbPrevious
            rArc = node
          
          # x equalWithEpsilon xr => falls exactly on the right edge of the beachsection
          else if dxr > -1e-9
            lArc = node
            rArc = node.rbNext
          
          # falls exactly somewhere in the middle of the beachsection
          else
            lArc = rArc = node
          
          break

    # at this point, keep in mind that lArc and/or rArc could be
    # undefined or null.

    # create a new beach section object for the site and add it to RB-tree
    newArc = @createBeachsection site
    @beachline.insertSuccessor lArc, newArc

    # cases:
    #

    # [null,null]
    # least likely case: new beach section is the first beach section on the
    # beachline.
    # This case means:
    #   no new transition appears
    #   no collapsing beach section
    #   new beachsection become root of the RB-tree
    if !lArc and !rArc
      return
    

    # [lArc,rArc] where lArc == rArc
    # most likely case: new beach section split an existing beach
    # section.
    # This case means:
    #   one new transition appears
    #   the left and right beach section might be collapsing as a result
    #   two new nodes added to the RB-tree
    if lArc is rArc
      # invalidate circle event of split beach section
      @detachCircleEvent(lArc)

      # split the beach section into two separate beach sections
      rArc = @createBeachsection(lArc.site)
      @beachline.insertSuccessor(newArc, rArc)

      # since we have a new transition between two beach sections,
      # a new edge is born
      newArc.edge = rArc.edge = @createEdge(lArc.site, newArc.site)

      # check whether the left and right beach sections are collapsing
      # and if so create circle events, to be notified when the point of
      # collapse is reached.
      @attachCircleEvent(lArc)
      @attachCircleEvent(rArc)
      return
    

    # [lArc,null]
    # even less likely case: new beach section is the *last* beach section
    # on the beachline -- this can happen *only* if *all* the previous beach
    # sections currently on the beachline share the same y value as
    # the new beach section.
    # This case means:
    #   one new transition appears
    #   no collapsing beach section as a result
    #   new beach section become right-most node of the RB-tree
    if lArc and !rArc
      newArc.edge = @createEdge(lArc.site,newArc.site)
      return


    # [null,rArc]
    # impossible case: because sites are strictly processed from top to bottom,
    # and left to right, which guarantees that there will always be a beach section
    # on the left -- except of course when there are no beach section at all on
    # the beach line, which case was handled above.
    # rhill 2011-06-02: No point testing in non-debug version
    #if (!lArc && rArc) ->
    #    throw "Voronoi.addBeachsection(): What is this I don't even"
    #    }

    # [lArc,rArc] where lArc != rArc
    # somewhat less likely case: new beach section falls *exactly* in between two
    # existing beach sections
    # This case means:
    #   one transition disappears
    #   two new transitions appear
    #   the left and right beach section might be collapsing as a result
    #   only one new node added to the RB-tree
    if lArc isnt rArc
      # invalidate circle events of left and right sites
      @detachCircleEvent(lArc)
      @detachCircleEvent(rArc)

      # an existing transition disappears, meaning a vertex is defined at
      # the disappearance point.
      # since the disappearance is caused by the new beachsection, the
      # vertex is at the center of the circumscribed circle of the left,
      # new and right beachsections.
      # http:#mathforum.org/library/drmath/view/55002.html
      # Except that I bring the origin at A to simplify
      # calculation
      lSite = lArc.site
      ax = lSite.x
      ay = lSite.y
      dx=site.x-ax
      dy=site.y-ay
      rSite = rArc.site
      cx=rSite.x-ax
      cy=rSite.y-ay
      d=2*(dx*cy-dy*cx)
      hb=dx*dx+dy*dy
      hc=cx*cx+cy*cy
      vertex = @createVertex((cy*hb-dy*hc)/d+ax, (dx*hc-cx*hb)/d+ay)

      # one transition disappear
      @setEdgeStartpoint(rArc.edge, lSite, rSite, vertex)

      # two new transitions appear at the new vertex location
      newArc.edge = @createEdge(lSite, site, undefined, vertex)
      rArc.edge = @createEdge(site, rSite, undefined, vertex)

      # check whether the left and right beach sections are collapsing
      # and if so create circle events, to handle the point of collapse.
      @attachCircleEvent(lArc)
      @attachCircleEvent(rArc)
      return


  attachCircleEvent : (arc) ->
    lArc = arc.rbPrevious
    rArc = arc.rbNext
    
    if !lArc or !rArc
      return # does that ever happen?
     
    lSite = lArc.site
    cSite = arc.site
    rSite = rArc.site

    # If site of left beachsection is same as site of
    # right beachsection, there can't be convergence
    if lSite is rSite
      return

    # Find the circumscribed circle for the three sites associated
    # with the beachsection triplet.
    # rhill 2011-05-26: It is more efficient to calculate in-place
    # rather than getting the resulting circumscribed circle from an
    # object returned by calling Voronoi.circumcircle()
    # http:#mathforum.org/library/drmath/view/55002.html
    # Except that I bring the origin at cSite to simplify calculations.
    # The bottom-most part of the circumcircle is our Fortune 'circle
    # event', and its center is a vertex potentially part of the final
    # Voronoi diagram.
    dx = cSite.x
    dy = cSite.y
    ax = lSite.x-dx
    ay = lSite.y-dy
    cx = rSite.x-dx
    cy = rSite.y-dy

    # If points l->c->r are clockwise, then center beach section does not
    # collapse, hence it can't end up as a vertex (we reuse 'd' here, which
    # sign is reverse of the orientation, hence we reverse the test.
    # http:#en.wikipedia.org/wiki/Curve_orientation#Orientation_of_a_simple_polygon
    # rhill 2011-05-21: Nasty finite precision error which caused circumcircle() to
    # return infinites: 1e-12 seems to fix the problem.
    d = 2*(ax*cy-ay*cx)
    if d >= -2e-12
      return

    ha = ax*ax+ay*ay
    hc = cx*cx+cy*cy
    x = (cy*ha-ay*hc)/d
    y = (ax*hc-cx*ha)/d
    ycenter = y+dy

    # Important: ybottom should always be under or at sweep, so no need
    # to waste CPU cycles by checking

    # recycle circle event object if possible
    circleEvent = @circleEventJunkyard.pop()
    if !circleEvent
      circleEvent = new CircleEvent()
  
    circleEvent.arc = arc
    circleEvent.site = cSite
    circleEvent.x = x+dx
    circleEvent.y = ycenter + Math.sqrt(x*x+y*y) # y bottom
    circleEvent.ycenter = ycenter
    arc.circleEvent = circleEvent

    # find insertion point in RB-tree: circle events are ordered from
    # smallest to largest
    predecessor = null
    node = @circleEvents.root
    
    while node
      if circleEvent.y < node.y or (circleEvent.y == node.y and circleEvent.x <= node.x) # potential ===/is here
        if node.rbLeft
          node = node.rbLeft
              
        else
          predecessor = node.rbPrevious
          break
      
      else
        if node.rbRight
          node = node.rbRight
        else 
          predecessor = node
          break
            
    @circleEvents.insertSuccessor(predecessor, circleEvent)
    if !predecessor
      @firstCircleEvent = circleEvent
    

  detachCircleEvent : (arc) ->
    circleEvent = arc.circleEvent
    if circleEvent
      
      if !circleEvent.rbPrevious
        @firstCircleEvent = circleEvent.rbNext
      
      @circleEvents.removeNode(circleEvent) # remove from RB-tree
      @circleEventJunkyard.push(circleEvent)
      arc.circleEvent = null

  # ---------------------------------------------------------------------------
  # Diagram completion methods

  # connect dangling edges (not if a cursory test tells us
  # it is not going to be visible.
  # return value:
  #   false: the dangling endpoint couldn't be connected
  #   true: the dangling endpoint could be connected
  
  connectEdge : (edge, bbox) ->
    # skip if end point already connected
    vb = edge.vb
    if !!vb
      return true

    # make local copy for performance purpose
    va = edge.va
    xl = bbox.xl
    xr = bbox.xr
    yt = bbox.yt
    yb = bbox.yb
    lSite = edge.lSite
    rSite = edge.rSite
    lx = lSite.x
    ly = lSite.y
    rx = rSite.x
    ry = rSite.y
    fx = (lx+rx)/2
    fy = (ly+ry)/2
    fm
    fb

    # if we reach here, this means cells which use this edge will need
    # to be closed, whether because the edge was removed, or because it
    # was connected to the bounding box.
    @cells[lSite.voronoiId].closeMe = true
    @cells[rSite.voronoiId].closeMe = true

    # get the line equation of the bisector if line is not vertical
    if ry isnt ly
      fm = (lx-rx)/(ry-ly)
      fb = fy-fm*fx
  
    # remember, direction of line (relative to left site):
    # upward: left.x < right.x
    # downward: left.x > right.x
    # horizontal: left.x == right.x
    # upward: left.x < right.x
    # rightward: left.y < right.y
    # leftward: left.y > right.y
    # vertical: left.y == right.y

    # depending on the direction, find the best side of the
    # bounding box to use to determine a reasonable start point

    # rhill 2013-12-02:
    # While at it, since we have the values which define the line,
    # clip the end of va if it is outside the bbox.
    # https:#github.com/gorhill/Javascript-Voronoi/issues/15
    # TODO: Do all the clipping here rather than rely on Liang-Barsky
    # which does not do well sometimes due to loss of arithmetic
    # precision. The code here doesn't degrade if one of the vertex is
    # at a huge distance.

    # special case: vertical line
    if fm is undefined
      # doesn't intersect with viewport
      if fx < xl or fx >= xr
        return false
      # downward
      if lx > rx
        if !va or va.y < yt
          va = @createVertex(fx, yt)
        
        else if va.y >= yb
          return false
            
        vb = @createVertex(fx, yb)
    
      # upward
      else 
        if !va or va.y > yb
          va = @createVertex(fx, yb)

        else if va.y < yt
          return false
      
        vb = @createVertex(fx, yt)
        
    # closer to vertical than horizontal, connect start point to the
    # top or bottom side of the bounding box
    else if fm < -1 or fm > 1
      # downward
      if lx > rx
        if !va or va.y < yt
          va = @createVertex((yt-fb)/fm, yt)
        
        else if va.y >= yb
          return false
        
        vb = @createVertex((yb-fb)/fm, yb)
    
      # upward
      else
        if !va or va.y > yb
          va = @createVertex((yb-fb)/fm, yb)
          
        else if va.y < yt
          return false
          
        vb = @createVertex((yt-fb)/fm, yt)
     
    # closer to horizontal than vertical, connect start point to the
    # left or right side of the bounding box
    else
        # rightward
      if ly < ry
        if !va or va.x < xl
          va = @createVertex(xl, fm*xl+fb)
        
        else if va.x >= xr
          return false
      
        vb = @createVertex(xr, fm*xr+fb)
    
      # leftward
      else 
        if !va or va.x > xr
          va = @createVertex(xr, fm*xr+fb)
          
        else if va.x < xl
          return false
        
        vb = @createVertex(xl, fm*xl+fb)
          
      
    edge.va = va
    edge.vb = vb

    return true


  # line-clipping code taken from:
  #   Liang-Barsky function by Daniel White
  #   http:#www.skytopia.com/project/articles/compsci/clipping.html
  # Thanks!
  # A bit modified to minimize code paths
  clipEdge : (edge, bbox) ->
    ax = edge.va.x
    ay = edge.va.y
    dx = edge.vb.x
    dy = edge.vb.y
    t0 = 0
    t1 = 1
    dx = dx-ax
    dy = dy-ay
    
    # left
    q = ax-bbox.xl
    if dx == 0 && q <0
      return false
    
    r = -q/dx
    
    if dx<0
      if r < t0
        return false
      if r<t1 
        t1=r

    else if dx>0
      if r>t1
        return false
      if r>t0
        t0=r
      
    # right
    q = bbox.xr-ax
    
    if dx == 0 && q<0 
      return false
    r = q/dx
    
    if dx<0
      if r>t1 
        return false
      if r>t0
        t0=r
    else if dx>0
      if r<t0
        return false
      if r<t1
        t1=r
  
    # top
    q = ay-bbox.yt
    
    if dy == 0 && q<0 
      return false
    
    r = -q/dy
    
    if dy<0
      if r<t0
        return false
      if r<t1
        t1=r
    
    else if dy>0
      if r>t1
        return false
      if r>t0
        t0=r
      
    # bottom        
    q = bbox.yb-ay
    if dy == 0 && q<0
      return false
    r = q/dy
    
    if dy<0
      if r>t1
        return false
      if r>t0
        t0=r
      
    else if dy>0
      if r<t0 
        return false
      if r<t1
        t1=r

    # if we reach this point, Voronoi edge is within bbox

    # if t0 > 0, va needs to change
    # rhill 2011-06-03: we need to create a new vertex rather
    # than modifying the existing one, since the existing
    # one is likely shared with at least another edge
    if t0 > 0
      edge.va = @createVertex(ax+t0*dx, ay+t0*dy)


    # if t1 < 1, vb needs to change
    # rhill 2011-06-03: we need to create a new vertex rather
    # than modifying the existing one, since the existing
    # one is likely shared with at least another edge
    if t1 < 1
      edge.vb = @createVertex(ax+t1*dx, ay+t1*dy)


    # va and/or vb were clipped, thus we will need to close
    # cells which use this edge.
    if  t0 > 0 or t1 < 1
      @cells[edge.lSite.voronoiId].closeMe = true
      @cells[edge.rSite.voronoiId].closeMe = true
  

    return true

  # Connect/cut edges at bounding box
  clipEdges : (bbox) ->
    # connect all dangling edges to bounding box
    # or get rid of them if it can't be done
    edges = @edges
    iEdge = edges.length
    edge
    abs_fn = Math.abs

    # iterate backward so we can splice safely
    while iEdge--
      edge = edges[iEdge]
      # edge is removed if:
      #   it is wholly outside the bounding box
      #   it is looking more like a point than a line
      if !@connectEdge(edge, bbox) or !@clipEdge(edge, bbox) or (abs_fn(edge.va.x-edge.vb.x) < 1e-9 and abs_fn(edge.va.y-edge.vb.y)<1e-9)
        edge.va = edge.vb = null
        edges.splice(iEdge,1)


  # Close the cells.
  # The cells are bound by the supplied bounding box.
  # Each cell refers to its associated site, and a list
  # of halfedges ordered counterclockwise.
  closeCells : (bbox) ->
    xl = bbox.xl
    xr = bbox.xr
    yt = bbox.yt
    yb = bbox.yb
    cells = @cells
    iCell = cells.length
    cell
    iLeft
    halfedges
    nHalfedges
    edge
    va
    vb
    vz
    lastBorderSegment
    abs_fn = Math.abs

    while iCell--
      cell = cells[iCell]
      # prune, order halfedges counterclockwise, then add missing ones
      # required to close cells
      if !cell.prepareHalfedges()
        continue
      
      if !cell.closeMe
        continue
    
      # find first 'unclosed' point.
      # an 'unclosed' point will be the end point of a halfedge which
      # does not match the start point of the following halfedge
      halfedges = cell.halfedges
      nHalfedges = halfedges.length
      # special case: only one site, in which case, the viewport is the cell
      # ...

      # all other cases
      iLeft = 0
      while iLeft < nHalfedges
        va = halfedges[iLeft].getEndpoint()
        vz = halfedges[(iLeft+1) % nHalfedges].getStartpoint()
        # if end point is not equal to start point, we need to add the missing
        # halfedge(s) up to vz
        if (abs_fn(va.x-vz.x)>=1e-9 or abs_fn(va.y-vz.y)>=1e-9)

          # rhill 2013-12-02:
          # "Holes" in the halfedges are not necessarily always adjacent.
          # https:#github.com/gorhill/Javascript-Voronoi/issues/16

          # find entry point:
          switch true

            # walk downward along left side
            when @equalWithEpsilon(va.x,xl) and @lessThanWithEpsilon(va.y,yb)
              lastBorderSegment = @equalWithEpsilon(vz.x,xl)
              ty = yb
              if lastBorderSegment
                ty = vz.y 
              vb = @createVertex(xl, ty)
              edge = @createBorderEdge(cell.site, va, vb)
              iLeft++
              halfedges.splice(iLeft, 0, @createHalfedge(edge, cell.site, null))
              nHalfedges++
              if lastBorderSegment
                break 
              va = vb
                # fall through

            # walk rightward along bottom side
            when @equalWithEpsilon(va.y,yb) && @lessThanWithEpsilon(va.x,xr)
              lastBorderSegment = @equalWithEpsilon(vz.y,yb)
              tx = xr
              if lastBorderSegment
                tx = vz.x
              vb = @createVertex(tx, yb)
              edge = @createBorderEdge(cell.site, va, vb)
              iLeft++
              halfedges.splice(iLeft, 0, @createHalfedge(edge, cell.site, null))
              nHalfedges++
              if lastBorderSegment
                break
              va = vb
                # fall through

            # walk upward along right side
            when @equalWithEpsilon(va.x,xr) and @greaterThanWithEpsilon(va.y,yt)
              lastBorderSegment = @equalWithEpsilon(vz.x,xr)
              ty = yt
              if lastBorderSegment
                ty = vz.y
              vb = @createVertex(xr, ty)
              edge = @createBorderEdge(cell.site, va, vb)
              iLeft++
              halfedges.splice(iLeft, 0, @createHalfedge(edge, cell.site, null))
              nHalfedges++
              if lastBorderSegment 
                break 
              va = vb
                # fall through

            # walk leftward along top side
            when @equalWithEpsilon(va.y,yt) and @greaterThanWithEpsilon(va.x,xl)
              lastBorderSegment = @equalWithEpsilon(vz.y,yt)
              tx = xl
              if lastBorderSegment
                tx = vz.x
              vb = @createVertex(tx, yt)
              edge = @createBorderEdge(cell.site, va, vb)
              iLeft++
              halfedges.splice(iLeft, 0, @createHalfedge(edge, cell.site, null))
              nHalfedges++
              if lastBorderSegment
                break
              va = vb
              # fall through

              # walk downward along left side
              lastBorderSegment = @equalWithEpsilon(vz.x,xl)

              ty = yb
              if lastBorderSegment
                ty = vz.y
              vb = @createVertex(xl, ty)
              
              edge = @createBorderEdge(cell.site, va, vb)
              iLeft++
              halfedges.splice(iLeft, 0, @createHalfedge(edge, cell.site, null))
              nHalfedges++
              if lastBorderSegment
                break
              va = vb
              # fall through

              # walk rightward along bottom side
              lastBorderSegment = @equalWithEpsilon(vz.y,yb)
              tx = xr
              if lastBorderSegment
                tx = vz.x
              vb = @createVertex(tx, yb)
              edge = @createBorderEdge(cell.site, va, vb)
              iLeft++
              halfedges.splice(iLeft, 0, @createHalfedge(edge, cell.site, null))
              nHalfedges++
              if lastBorderSegment 
                break
              va = vb
              # fall through

              # walk upward along right side
              lastBorderSegment = @equalWithEpsilon(vz.x,xr)
              ty = yt
              if lastBorderSegment
                ty = vz.y
              vb = @createVertex(xr, ty)
              edge = @createBorderEdge(cell.site, va, vb)
              iLeft++
              halfedges.splice(iLeft, 0, @createHalfedge(edge, cell.site, null))
              nHalfedges++
              if lastBorderSegment
                break
              # fall through

            else
              throw "Voronoi.closeCells() > this makes no sense!"
        
        
        iLeft++
    
      cell.closeMe = false
    


  # ---------------------------------------------------------------------------
  # Debugging helper

  dumpBeachline : (y) ->
    console.log('Voronoi.dumpBeachline(%f) > Beachsections, from left to right:', y)
    if !@beachline
      console.log('  None')
    
    else 
      bs = @beachline.getFirst(@beachline.root)
      while bs
        console.log('  site %d: xl: %f, xr: %f', bs.site.voronoiId, @leftBreakPoint(bs, y), @rightBreakPoint(bs, y))
        bs = bs.rbNext
       
    
  # ---------------------------------------------------------------------------
  # Helper: Is Segment - returns true if this site is a segment endpoint

  isSegment : (site) ->
    for edge in @segments
      if site is edge[0] or site is edge[1]
        return true
    false



  # ---------------------------------------------------------------------------
  # Helper: Quantize sites

  # rhill 2013-10-12:
  # This is to solve https:#github.com/gorhill/Javascript-Voronoi/issues/15
  # Since not all users will end up using the kind of coord values which would
  # cause the issue to arise, I chose to let the user decide whether or not
  # he should sanitize his coord values through this helper. This way, for
  # those users who uses coord values which are known to be fine, no overhead is
  # added.

  quantizeSites : (sites) ->
    e = @epsilon
    n = sites.length
    site

    while n--
      site = sites[n]
      site.x = Math.floor(site.x / e) * e
      site.y = Math.floor(site.y / e) * e
  

  # ---------------------------------------------------------------------------
  # Helper: Recycle diagram: all vertex, edge and cell objects are
  # "surrendered" to the Voronoi object for reuse.
  # TODO: rhill-voronoi-core v2: more performance to be gained
  # when I change the semantic of what is returned.

  recycle : (diagram) ->
    if diagram
      if  diagram instanceof Diagram
        @toRecycle = diagram
      
      else
        throw 'Voronoi.recycleDiagram() > Need a Diagram object.'
 

  # ---------------------------------------------------------------------------
  # Top-level Fortune loop

  # rhill 2011-05-19:
  #   Voronoi sites are kept client-side now, to allow
  #   user to freely modify content. At compute time,
  #   *references* to sites are copied locally.

  # sites is a list of Vec2
  # bbox is a boundingbox object
  # segments is a list of pairs of pointers to Vec2 in sites

  compute : (sites, bbox, segments) ->
    # to measure execution time
    startTime = new Date()

    # init internal state
    @reset()

    # Oni Addition. Keep a record of the segments
    @segments = segments

    # any diagram data available for recycling?
    # I do that here so that this is included in execution time
    if @toRecycle
      @vertexJunkyard = @vertexJunkyard.concat(@toRecycle.vertices)
      @edgeJunkyard = @edgeJunkyard.concat(@toRecycle.edges)
      @cellJunkyard = @cellJunkyard.concat(@toRecycle.cells)
      @toRecycle = null

    # Initialize site event queue
    siteEvents = sites.slice(0)
    siteEvents.sort( (a,b) ->
      r = b.y - a.y
      if r
        return r
      return b.x - a.x
    )

    # process queue
    site = siteEvents.pop()
    siteid = 0
    xsitex  # to avoid duplicate sites
    xsitey
    cells = @cells
    circle

    # main loop
    loop
      # we need to figure whether we handle a site or circle event
      # for this we find out if there is a site event and it is
      # 'earlier' than the circle event
      circle = @firstCircleEvent

      # add beach section
      if (site and (!circle or site.y < circle.y or (site.y == circle.y and site.x < circle.x)))
        # only if site is not a duplicate
        if site.x != xsitex || site.y != xsitey
          cells[siteid] = @createCell(site)
          site.voronoiId = siteid++
          
          # then create a beachsection for that site
          @addBeachsection(site)

          # remember last site coords to detect duplicate
          xsitey = site.y
          xsitex = site.x
      

        site = siteEvents.pop()
        

      # remove beach section
      else if circle
        @removeBeachsection(circle.arc)

      # all done, quit
      else
        break
    
    # wrapping-up:
    #   connect dangling edges to bounding box
    #   cut edges as per bounding box
    #   discard edges completely outside bounding box
    #   discard edges which are point-like
    @clipEdges(bbox)

    #   add missing edges in order to close opened cells
    @closeCells(bbox)

    # to measure execution time
    stopTime = new Date()

    # prepare return values
    diagram = new Diagram()
    diagram.cells = @cells
    diagram.edges = @edges
    diagram.vertices = @vertices
    diagram.execTime = stopTime.getTime()-startTime.getTime()

    # clean up
    @reset()

    return diagram

module.exports =
  Voronoi : Voronoi

