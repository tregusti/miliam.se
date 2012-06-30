fs = require 'fs'
Path = require 'path'
child = require 'child_process'

Guard = require './guard'

Entry = require './entry'

loadNextEntry = (entries, paths, done) ->
  if paths.length is 0
    done()
  else
    path = paths.shift()
    entry = new Entry path
    entry.on 'load', ->
      entries.push entry
      loadNextEntry entries, paths, done
    entry.on 'error', (err) ->
      done err


class EntryList

  constructor: (datapath) ->
    Guard.string 'datapath', datapath
    @datapath = datapath

  get: (options, callback) ->
    path = @datapath
    if options instanceof Function
      callback = options
      options = null
    else
      [year, month, date] = [options?.year || null, options?.month || null, options?.date || null]

    path = Path.join path, part for part in [year, month, date] when part?
    child.exec "find -L #{path} -name info.txt | sed 's/info.txt//'", (err, list) ->
      callback err, null if err
      paths = list.trim().split '\n'
      entries = []

      loadNextEntry entries, paths, (err) ->
        if err
          callback err, null
        else
          callback null, entries

module.exports = EntryList