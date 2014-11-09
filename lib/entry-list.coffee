fs = require 'fs'
Path = require 'path'
child = require 'child_process'

Guard = require './guard'

Entry = require './entry'
NotFoundError = require './errors/notfound'
ArgumentError = require './errors/argument'

months = ' Januari Februari Mars April Maj Juni Juli Augusti September Oktober November December'.split ' '

class EntryList
  constructor: (year=null, month=null, date=null) ->
    Object.defineProperty @, 'title',
      enumerable: true
      get: ->
        s = ''
        if year
          s = "#{year}"
          if month
            s = "#{months[month|0]} #{s}"
            if date
              s = "#{date|0} #{s}".toLowerCase()
        s
    Object.defineProperty @, 'subtitle',
      enumerable: true
      get: ->
        s = ''
        if year
          s = year
          if month
            s = "#{months[month|0]} #{s}".toLowerCase()
            if date
              return "den #{date|0} #{s}"
        if s then "under #{s}" else ""



loadNextEntry = (entries, paths, limit, done) ->
  if paths.length is 0
    done null, false
  else if limit is 0
    done null, true
  else
    path = paths.shift()
    Entry.load path, (err, entry) ->
      if err
        done err
      else
        entries.push entry
        loadNextEntry entries, paths, limit - 1, done


EntryList.load = (path, options, callback) ->
  # If no options specified, shift arguments
  [options, callback] = [{}, options] if options instanceof Function

  options.limit ||= -1 # Default to -1, equalling unlimited
  options.offset ?= 0

  # Error handling
  return callback new ArgumentError('path'), null unless path

  path = Path.join(path, part or '') for part in [options.year, options.month, options.date] when part?

  child.exec "find -L #{path} -name info.txt | sed 's/\\/info.txt//'", (err, list) ->
    # callback err, null if err
    list = list.trim() or null
    return callback new NotFoundError path unless list
    paths = list.split('\n').sort().reverse()
    paths = paths.slice options.offset

    entries = []

    loadNextEntry entries, paths, options.limit, (err, more) ->
      if err
        callback err, null
      else
        el = new EntryList options.year, options.month, options.date
        el.entries = entries
        el.more = more
        callback null, el

module.exports = EntryList
