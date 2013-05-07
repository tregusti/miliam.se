fs = require 'fs'
Path = require 'path'

marked = require 'marked'

module.exports = (req, res, next) ->
  pagesRoot = Path.join config.get('paths:data'), 'pages'
  filepath = Path.join pagesRoot, req.path
  filepath = "#{filepath}.md"
  # check if valid file path
  return next() unless filepath.indexOf(pagesRoot) is 0
  fs.readFile filepath, 'utf8', (err, data) ->
    return next() if err
    res.render 'page',
      content: marked data