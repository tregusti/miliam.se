fs = require 'fs'
Path = require 'path'

marked = require 'marked'

module.exports = (req, res, next) ->
  path = Path.join config.get('paths:data'), 'pages', 'om.md'
  fs.readFile path, 'utf8', (err, data) ->
    return next() if err
    res.render 'page',
      content: marked data