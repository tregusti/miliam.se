Path = require 'path'
express = require 'express'

Entry = require '../lib/entry'
EntryList = require '../lib/entry-list'

datapath = Path.join __dirname, '..', 'data'

exports.list = (req, res) ->
  [year, month, date] = req.params
  el= new EntryList datapath
  entries = el.get (err, entries) ->
    res.render "list",
      title: 'Lista',
      entries: entries

exports.entry = (req, res) ->
  [year, month, date, slug] = req.params
  entry = new Entry Path.join(datapath, year, month, date, slug)
  entry.on 'load', ->
    res.render "entry",
      title: entry.title,
      hasImage: entry.image?,
      text: entry.text,
      date: entry.humanDate,
      time: entry.humanTime,
      thumb: entry.image?.thumb.replace datapath, ''

exports.entryImage = (req, res) ->
  middleware = express.static __dirname + "/../data"
  middleware req, res