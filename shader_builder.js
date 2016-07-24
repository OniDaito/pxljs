
// https://github.com/gulpjs/gulp/blob/master/docs/writing-a-plugin/README.md

var through = require('through2');
var PluginError = require('gulp-util').PluginError;
var fs = require('fs');
var path = require('path');

var PLUGIN_NAME = 'shader_builder';

// Lookup chunks in the related files
_matchWithChunks = function(shader_raw, path) {
  var matches = shader_raw.match(/\{\{ShaderChunk\.[a-zA-Z_]+\}\}/g);
    
  if (matches != undefined){
    for (var midx in matches) { 
      var match = matches[midx];
      var chunk_name = match.replace("}}","").split(".")[1];
      //var is = shader_raw.indexOf(match);
      //shader_raw = shader_raw.slice(is,is+match.length);
      var buf = fs.readFileSync (path + "/" + chunk_name + ".chunk", {encoding: 'utf-8'});
      var chunk_raw = buf.toString('utf8');
      shader_raw = shader_raw.replace(match,chunk_raw);

    }
  }

  return shader_raw;
}

// Split the glsl shader file into it's two components, fragment and vertex
_splitShader = function(s) {   
  var sv, sf;
  
  sv = sf = "";
  pv = s.indexOf("##>VERTEX");
  pf = s.indexOf("##>FRAGMENT");
 
  if (pv != -1) {
    if (pf != -1 && pf > pv) {
      sv = s.slice(pv + 9, pf)
    }
    else if (pf != -1 && pf < pv) {
      sv = s.slice(pv + 9)
    }
  }

  if (pf != -1) {
    if (pv != -1 && pv > pf) {
      sf = s.slice(pf + 11, pv)
    }
    else if (pf != -1 && pv < pf) {
      sf = s.slice(pf + 11)
    }
  }
  return [sv,sf];
}

// Take each line and make it proper javascript
_javascriptize = function(shader_txt,var_name) {
  var shader_js = "var " + var_name + "=" + "\n";  
  var lines = shader_txt.split("\n");
  for (var lidx =0; lidx < lines.length; lidx++){
    var newline = lines[lidx];
    newline = newline.replace("\n","");
    newline = newline.replace("\r","");

    shader_js = shader_js + '\"' + newline + '\\n"';

    if ((lidx + 1) < lines.length){
      shader_js = shader_js + ' +\n';
    }
  
  }

  shader_js = shader_js + ";";
  return shader_js;
}

module.exports = function(opts) {

  opts = opts || {};

  var _parse_chunk = function(file, encoding, callback) {

    if (file.isStream()) {
      this.emit('error', new PluginError(PLUGIN_NAME, 'Streams not supported!'));
      return;
    }

    if (file.isNull()) {
        return callback(null, file);
    }

    // Now perform the actual transformation of the chunks
    var shader_raw = file.contents.toString('utf8');

    // We assume that chunks are in a subdir relative to the glsl files called 'chunks'
    var shader_linked = _matchWithChunks(shader_raw, path.dirname(file.path) + "/chunks");
    
    // Split the shader
    var parts =_splitShader(shader_linked);
    var shader_vertex = parts[0];
    var shader_fragment = parts[1];

    // Convert each part
    shader_vertex = _javascriptize(shader_vertex, "shader_vertex");
    shader_fragment = _javascriptize(shader_fragment, "shader_fragment");

    var shader_final = shader_vertex + "\n" + shader_fragment + "\n\nmodule.exports = { vertex : shader_vertex, fragment: shader_fragment };"

    // Combine into final js
    file.contents = new Buffer(shader_final);

    callback(null,file);
  }; 

  return through.obj(_parse_chunk);
};