fs = require 'fs'
Path = require 'path'
child = require 'child_process'

Guard = require './guard'

Entry = require './entry'
NotFoundError = require './errors/notfound'
ArgumentError = require './errors/argument'

loadNextEntry = (entries, paths, done) ->
  if paths.length is 0
    done()
  else
    path = paths.shift()
    Entry.load path, (err, entry) ->
      if err
        done err
      else
        entries.push entry
        loadNextEntry entries, paths, done


# class EntryList
#
#   constructor: (datapath) ->
#     Guard.string 'datapath', datapath
#     @datapath = datapath
#
#   get: (options, callback) ->
#     path = @datapath
#     if options instanceof Function
#       callback = options
#       options = null
#     else
#       [year, month, date] = [options?.year || null, options?.month || null, options?.date || null]
#
#     path = Path.join path, part for part in [year, month, date] when part?
#     child.exec "find -L #{path} -name info.txt | sed 's/\\/info.txt//'", (err, list) ->
#       return callback new NotFoundError(path), null if err
#
#       list = list.trim() or null
#
#       return callback new NotFoundError(path), null unless list
#
#       paths = list.split('\n').reverse()
#       entries = []
#
#       loadNextEntry entries, paths, (err) ->
#         if err
#           callback err, null
#         else
#           callback null, entries


load = (path, options, callback) ->
  # If no options specified, shift arguments
  [options, callback] = [{}, options] if options instanceof Function

  # Error handling
  return callback new ArgumentError('path'), null unless path

  path = Path.join path, part for part in [options.year, options.month, options.date] when part?

  child.exec "find -L #{path} -name info.txt | sed 's/\\/info.txt//'", (err, list) ->
    # callback err, null if err
    list = list.trim() or null
    callback new NotFoundError path unless list
    paths = list.split('\n').sort().reverse()

    entries = []

    loadNextEntry entries, paths, (err) ->
      if err
        callback err, null
      else
        callback null, entries

module.exports.load = load