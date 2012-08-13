fs = require 'fs'
Path = require 'path'
child = require 'child_process'

Guard = require './guard'

Entry = require './entry'
NotFoundError = require './errors/notfound'
ArgumentError = require './errors/argument'

loadNextEntry = (entries, paths, limit, done) ->
  if paths.length is 0 or limit is 0
    done()
  else
    path = paths.shift()
    Entry.load path, (err, entry) ->
      if err
        done err
      else
        entries.push entry
        loadNextEntry entries, paths, limit - 1, done


load = (path, options, callback) ->
  # If no options specified, shift arguments
  [options, callback] = [{}, options] if options instanceof Function

  options.limit ||= -1 # Default to -1, equalling unlimited

  # Error handling
  return callback new ArgumentError('path'), null unless path

  path = Path.join path, part for part in [options.year, options.month, options.date] when part?

  child.exec "find -L #{path} -name info.txt | sed 's/\\/info.txt//'", (err, list) ->
    # callback err, null if err
    list = list.trim() or null
    callback new NotFoundError path unless list
    paths = list.split('\n').sort().reverse()

    entries = []

    loadNextEntry entries, paths, options.limit, (err) ->
      if err
        callback err, null
      else
        callback null,
          entries: entries

module.exports.load = load