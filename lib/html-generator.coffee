marked = require 'marked'
renderer = new marked.Renderer

renderer.codespan = (text) ->
  "<q>#{text}</q>"

module.exports = (md) ->
  marked md,
    renderer: renderer