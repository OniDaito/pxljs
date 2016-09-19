# Shaders in PXLjs

Shaders come in two forms in PXLjs: custom and uber. The uber shader is provided for ease of use, but if you wish to write your own, you can! It's also possible to utilise PXLjs's shader builder script to simplify the construction of your shaders.


## The Ubershader

### shaderbuilder

In the gulp file, eagle eyed developers may see the **shader** build step. Inside the **src/shader** folder there lives a file called **uber.glsl**. This file contains the skeleton for the ubershader and highlights the way in which shaders are built from component parts in PXLjs.  

## Custom Shaders

## Contracts

### Default names for Vertex Shader Attributes

The following names are set in the default Contract class. If you want to use PXLjs geometry with your own shader, simply set the following attribute names in your shader and PXLjs will bind to these for you.

- **aVertexPosition** - vertexpBuffer
- **aVertexTexCoord** - vertextBuffer
- **aVertexNormal** - vertexnBuffer
- **aVertexColour** - vertexcBuffer
- **aVertexTangent** - vertexaBuffer
- **aVertexBarycentre** - vertexyBuffer
- **aVertexSkinWeight** - vertexwBuffer
- **aVertexBoneIndex** - vertexiBuffer


