Path = require 'path'
express = require 'express'

Entry = require '../lib/entry'
EntryList = require '../lib/entry-list'
NotFoundError = require '../lib/errors/notfound'

datapath = Path.join __dirname, '..', 'data'

exports.list = (req, res, next) ->
  [year, month, date] = req.params
  EntryList.load datapath, (err, entries) ->
    # TODO: Readd date filtering
    # opts = year: year, month: month, date: date

    if err
      next new NotFoundError req.path
    else
      res.render "list",
        title: 'Lista',
        entries: entries

exports.entry = (req, res, next) ->
  [year, month, date, slug] = req.params
  entry = Entry.load Path.join(datapath, year, month, date, slug), (err, entry) ->
    throw err if err
    res.render "entry", entry

exports.entryImage = (req, res) ->
  middleware = express.static __dirname + "/../data"
  middleware req, res