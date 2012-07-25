Path = require 'path'
express = require 'express'

Entry = require '../lib/entry'
EntryList = require '../lib/entry-list'
NotFoundError = require '../lib/errors/notfound'

datapath = config.get 'paths:data'

exports.list = (req, res, next) ->
  [year, month, date] = req.params
  opts = year: year, month: month, date: date
  EntryList.load datapath, opts, (err, entries) ->

    if err
      next new NotFoundError req.path
    else
      res.render "list",
        title: ''
        entries: entries

exports.entry = (req, res, next) ->
  [year, month, date, slug] = req.params
  entry = Entry.load Path.join(datapath, year, month, date, slug), (err, entry) ->
    throw err if err
    res.render "entry", entry

exports.entryImage = (req, res) ->
  middleware = express.static config.get 'paths:data'
  middleware req, res