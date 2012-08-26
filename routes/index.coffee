Path = require 'path'
express = require 'express'
fs = require 'fs'
marked = require 'marked'

Entry = require '../lib/entry'
EntryList = require '../lib/entry-list'
NotFoundError = require '../lib/errors/notfound'

datapath = config.get 'paths:data'


exports.entryImage = (req, res) ->
  middleware = express.static config.get 'paths:data'
  middleware req, res

files = (Path.basename file, '.coffee' for file in fs.readdirSync __dirname)
exports[name] = require "./#{name}" for name in files when name isnt "index"

exports.about = (req, res, next) ->
  path = Path.join config.get('paths:data'), 'pages', 'om.md'
  fs.readFile path, 'utf8', (err, data) ->
    return next() if err
    res.render 'page',
      content: marked data