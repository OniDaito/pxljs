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

An implementation of the Red Black Tree from the Javascript Implementation found
at https://github.com/gorhill/Javascript-Voronoi/blob/master/rhill-voronoi-core.js

###


###RedBlackTree###

class RedBlackTree
  constructor : () ->
    @root = null

  insertSuccessor : (node, successor) ->
    if node
      successor.rbPrevious = node
      successor.rbNext = node.rbNext
      
      if node.rbNext
        node.rbNext.rbPrevious = successor  
      
      node.rbNext = successor
    
      if node.rbRight   
        node = node.rbRight

        while node.rbLeft
          node = node.rbLeft
        
        node.rbLeft = successor
      
      else
        node.rbRight = successor
      parent = node
    
    else if @root
      node = @getFirst(@root)
      successor.rbPrevious = null
      successor.rbNext = node
      node.rbPrevious = successor
      node.rbLeft = successor
      parent = node
      
    else 
      successor.rbPrevious = successor.rbNext = null
     
      @root = successor
      parent = null
      
    successor.rbLeft = successor.rbRight = null
    successor.rbParent = parent
    successor.rbRed = true
   
    grandpa
    uncle
    node = successor

    while parent and parent.rbRed
      grandpa = parent.rbParent
      if parent is grandpa.rbLeft
        uncle = grandpa.rbRight
        if uncle and uncle.rbRed
          parent.rbRed = uncle.rbRed = false
          grandpa.rbRed = true
          node = grandpa
        
        else 
          if node is parent.rbRight
            @rotateLeft(parent)
            node = parent
            parent = node.rbParent
            
          parent.rbRed = false
          grandpa.rbRed = true
          @rotateRight(grandpa)
          
      else
        uncle = grandpa.rbLeft
        if (uncle && uncle.rbRed)
          parent.rbRed = uncle.rbRed = false
          grandpa.rbRed = true
          node = grandpa
            
        else
          if (node is parent.rbLeft)
            @rotateRight(parent)
            node = parent
            parent = node.rbParent
              
          parent.rbRed = false
          grandpa.rbRed = true
          @rotateLeft grandpa
          
          parent = node.rbParent

    @root.rbRed = false      

  removeNode : (node) ->
    if node.rbNext
      node.rbNext.rbPrevious = node.rbPrevious
  
    if node.rbPrevious
      node.rbPrevious.rbNext = node.rbNext
    
    node.rbNext = node.rbPrevious = null

    parent = node.rbParent
    left = node.rbLeft
    right = node.rbRight
    next

    if !left
      next = right

    else if !right
      next = left
    else
      next = @getFirst right
    if parent
      if parent.rbLeft is node
        parent.rbLeft = next      
      else
        parent.rbRight = next
  
    else
      @root = next
  
    # enforce red-black rules
    isRed

    if left and right
      isRed = next.rbRed
      next.rbRed = node.rbRed
      next.rbLeft = left
      left.rbParent = next
      if next isnt right
        parent = next.rbParent
        next.rbParent = node.rbParent
        node = next.rbRight
        parent.rbLeft = node
        next.rbRight = right
        right.rbParent = next
      
      else 
        next.rbParent = parent
        parent = next
        node = next.rbRight
    else
      isRed = node.rbRed
      node = next
  
    if node
      node.rbParent = parent
  
    if isRed
      return

    if node and node.rbRed
      node.rbRed = false
      return

    sibling
    loop
      if node is @root
        break
        
      if node is parent.rbLeft
        sibling = parent.rbRight
        
        if sibling.rbRed
          sibling.rbRed = false
          parent.rbRed = true
          @rotateLeft(parent)
          sibling = parent.rbRight
        
        if (sibling.rbLeft and sibling.rbLeft.rbRed) or (sibling.rbRight and sibling.rbRight.rbRed)
          if !sibling.rbRight or !sibling.rbRight.rbRed
            sibling.rbLeft.rbRed = false
            sibling.rbRed = true
            @rotateRight sibling
            sibling = parent.rbRight
            
          sibling.rbRed = parent.rbRed
          parent.rbRed = sibling.rbRight.rbRed = false
          @rotateLeft parent
          node = @root
          break
          
      else
        sibling = parent.rbLeft
        if (sibling.rbRed)
          sibling.rbRed = false
          parent.rbRed = true
          @rotateRight parent
          sibling = parent.rbLeft
          
        if (sibling.rbLeft and sibling.rbLeft.rbRed) or (sibling.rbRight and sibling.rbRight.rbRed)
          if !sibling.rbLeft or !sibling.rbLeft.rbRed
            sibling.rbRight.rbRed = false
            sibling.rbRed = true
            @rotateLeft sibling
            sibling = parent.rbLeft
        
          sibling.rbRed = parent.rbRed
          parent.rbRed = sibling.rbLeft.rbRed = false
          @rotateRight parent
          node = @root
          break
              
      sibling.rbRed = true
      node = parent
      parent = parent.rbParent

      break if node.rbRed 
    
    if node
      node.rbRed = false

  rotateLeft : (node) ->
    p = node
    q = node.rbRight
    parent = p.rbParent

    if parent
      if parent.rbLeft is p
        parent.rbLeft = q
      else
        parent.rbRight = q
    else
      @root = q
    
    q.rbParent = parent
    p.rbParent = q
    p.rbRight = q.rbLeft
    if p.rbRight
      p.rbRight.rbParent = p
  
    q.rbLeft = p

  rotateRight : (node) ->
    p = node
    q = node.rbLeft
    parent = p.rbParent;
    
    if parent
      if parent.rbLeft is p
        parent.rbLeft = q
      else
        parent.rbRight = q
    
    else
      @root = q

    q.rbParent = parent
    p.rbParent = q
    p.rbLeft = q.rbRight
  
    if p.rbLeft
      p.rbLeft.rbParent = p
  
    q.rbRight = p

  getFirst : (node) ->
    while node.rbLeft
      node = node.rbLeft

    node

  getLast : (node) ->
    while node.rbRight
      node = node.rbRight

    node
  
module.exports =
  RedBlackTree : RedBlackTree
