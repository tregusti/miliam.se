# util = require 'util'
# fs = require 'fs'
Path = require 'path'
#
Entry = require '../entry'
ArgumentError = require '../errors/argument'
# log = require('../log') "Importer"

cp = require('child_process')

createImageObject = (base, name) ->
  o = {}
  o["w#{w}"] = Path.join base, "#{name}.w#{w}.jpg" for w in [320, 640, 1024]
  o

Importer =
  load: (path, callback) ->
    return callback new ArgumentError('path', path), null unless path
    Entry.load path, (err, entry) ->
      return callback err, null if err

      cp.exec "find -L #{entry.basepath} -regex '.*\/.*.jpg$'", (err, str) ->
        return callback err, null if err
        str = str.trim()
        return unless str

        files = for file in str.split '\n' then Path.basename file, '.jpg'
        if files.length
          entry.images = for file in files then createImageObject entry.basepath, file

        callback null, entry


# class Importer
#   constructor: (path) ->
#     Guard.string 'path', path
#     log.info "Create new Importer instance"
#     @basepath = path
#
#   entry: (callback) ->
#     log.debug 'Creating Entry instance'
#     entry = new Entry @basepath
#     entry.on 'load', ->
#       callback null, entry
#       entry.off 'load'
#       entry.off 'error'
#     entry.on 'error', (err) ->
#       callback err, null


module.exports = Importer