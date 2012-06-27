Path = require 'path'

Entry = require '../lib/entry'

datapath = Path.join __dirname, '..', 'data'

exports.index = (req, res) ->
  res.render "index",
    title: "Express"

exports.entry = (req, res) ->
  [year, month, slug] = req.params
  entry = new Entry Path.join(datapath, year, month, slug)
  entry.on 'load', ->
    res.render "entry", entry