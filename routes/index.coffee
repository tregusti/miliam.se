Path = require 'path'
express = require 'express'

Entry = require '../lib/entry'
EntryList = require '../lib/entry-list'
NotFoundError = require '../lib/errors/notfound'

datapath = Path.join __dirname, '..', 'data'

exports.list = (req, res, next) ->
  [year, month, date] = req.params
  el = new EntryList datapath
  opts = year: year, month: month, date: date

  el.get opts, (err, entries) ->
    if err
      console.dir err
      next new NotFoundError req.path
    else
      res.render "list",
        title: 'Lista',
        entries: entries

exports.entry = (req, res, next) ->
  [year, month, date, slug] = req.params
  entry = new Entry Path.join(datapath, year, month, date, slug)

  entry.on 'error', (err) ->
    next()

  entry.on 'load', ->
    res.render "entry",
      title: entry.title,
      hasImage: entry.image?,
      html: entry.html,
      date: entry.humanDate,
      time: entry.humanTime,
      thumb: entry.image?.thumb.replace datapath, ''

exports.entryImage = (req, res) ->
  middleware = express.static __dirname + "/../data"
  middleware req, res