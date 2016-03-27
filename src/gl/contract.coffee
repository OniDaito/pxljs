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

util = require '../util/util'


### Contract ###
# Holds the actual mapping between webgl shader inputs and the names of the variables to be mapped
# A shader holds a contract with uniforms and attributes but has no roles. 
# A contract on a node or other js object has roles but no uniforms or attributes. We match the 
# two together. 
# TODO - Should we hold size information in the contract?

class Contract
  
  # Like matches only this holds the previous values for the uniforms only
  # we keep the cache just once and globally for now, rather than on both sides of the
  # shader equation
  

  # Match two contracts together. Left hand is the shader part. Right hand is the node part
  # Make both equal to each other, as best as we can, prioritising the shader side 
  # TODO - there is duplication of data here we will need to sort out.

  @join : (shader_contract, obj) ->

    for u in shader_contract.uniforms

      if obj.contract.roles[u.name]?

        obj_var = obj[obj.contract.roles[u.name]] 
        shader_contract.matches[u.name] = obj_var
        obj.contract.matches[u.name] = obj_var
  

    for a in shader_contract.attributes
      if obj.contract.roles[a.name]?
        obj_var = obj[obj.contract.roles[a.name]] 
        shader_contract.matches[a.name] = obj_var
        obj.contract.matches[a.name] = obj_var   

    shader_contract

  constructor : (@attributes, @uniforms, user_roles) ->

    # Roles are text to text mappings on the node side
    # Essentially what role does a node variable play in
    # this shader

    @roles = {}

    # Copy any passed in @roles
    if user_roles?
      for key of user_roles
        @roles[key] = user_roles[key]

    # matches are a direct mapping between either a uniform or 
    # attribute and a node variable. This acts as a cache
    @matches = {}

  # Add a variable to the contract
  # role - the name of the variable in the shader
  # varname - the javascript varible providing the data
  add : (role, varname) ->
    @roles[role] = varname
    @


 
  # Check to see if a rolename is listed
  hasRoleValue : (role_name) ->
    for key of @roles
      if @roles[key] == role_name
        return true
    false

  # Find any unmatched uniforms or attributes
  findUnmatched : () ->
    unmatched = []
    if @_cached?
      for u in @uniforms    
        if not @matches[u.name]?
          unmatched.push u
      
      for a in @attributes
        if not @matches[a.name]?
          unmatched.push a

    unmatched

module.exports = 
  Contract : Contract