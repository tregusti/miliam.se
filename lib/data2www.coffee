Path = require 'path'

module.exports = (path) ->
  datapath = config.get 'paths:data'
  path = Path.resolve path
  if path.substr(0, datapath.length) is not datapath
    throw new Error 'Path not inside data path'
  path.substr datapath.length