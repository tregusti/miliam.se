Path = require 'path'
express = require 'express'
fs = require 'fs'
marked = require 'marked'

Entry = require '../lib/entry'
EntryList = require '../lib/entry-list'
NotFoundError = require '../lib/errors/notfound'

datapath = config.get 'paths:data'

exports.list = (req, res, next) ->
  [year, month, date] = req.params
  opts = year: year, month: month, date: date
  EntryList.load datapath, opts, (err, list) ->

    if err
      next new NotFoundError req.path
    else
      res.render "list",
        title: list.title
        entries: list.entries

exports.entry = (req, res, next) ->
  [year, month, date, slug] = req.params
  entry = Entry.load Path.join(datapath, year, month, date, slug), (err, entry) ->
    throw err if err
    res.render "entry",
      entry       : entry
      url         : entry.url
      title       : entry.title
      description : entry.description

exports.entryImage = (req, res) ->
  middleware = express.static config.get 'paths:data'
  middleware req, res

exports.rss = require './rss'
exports.tracker = require './tracker'

exports.about = (req, res, next) ->
  path = Path.join config.get('paths:data'), 'pages', 'om.md'
  fs.readFile path, 'utf8', (err, data) ->
    return next() if err
    res.render 'page',
      content: marked data