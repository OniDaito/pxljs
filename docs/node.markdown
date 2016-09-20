# Node

This page describes the Node class and the associate scene-graph style approach that PXLjs takes.

## Overview

The [Node](https://api.pxljs.com/core/node.html) class is the building block of PXLjs. It combines the [Geometry]() class with matrices, shaders and other information required to present vertices to the world.

Nodes can also have child nodes, thus creating hierarchies of matrices. Some classes automatically create node trees, such as the [MD5Model]() class. In this way, you can create groups of related objects.

Geometry can be shared between nodes. You can add the same geometry to multiple nodes. This results is saving space on the GPU but spawing more draw calls. [materials]() are added to nodes to control the appearance of the geometry on that node.  

Shaders can also be shared between nodes. The [ubershader]() class, when given a node or selection of nodes, will check them to see what dependencies it needs, then build itself accordingly. The ubershader is valid for as long as the [materials]() on the node don't change.
 
Materials and shaders are passed down the node tree. For example a parent node with the [BasicColourMaterial]() and 5 child nodes, each with geometry, will force these 5 child nodes to be drawn with a basic colour. However, you can add a different material to one of these child nodes and that single child node will *overide* that of it's parent. The same is true for shaders.

This object-orientated approach to nodes is very similar to how nodes work in Blender and other such packages. You don't have to create deep hierarchies of nodes. You can ignore the hierarchy all together, but the minimum required to draw an object to the screen in PXLjs is a node, shader, material, camera and geometry.
