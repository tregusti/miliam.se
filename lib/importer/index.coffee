util = require 'util'
fs = require 'fs'
Path = require 'path'

Entry = require '../entry'
Guard = require '../guard'
log = require '../log'

class Importer
  constructor: (path) ->
    Guard.string 'path', path
    log.info "Create new Importer instance"
    @basepath = path

  entry: (callback) ->
    log.debug 'Creating Entry instance'
    entry = new Entry @basepath
    entry.on 'load', ->
      callback null, entry
      entry.off 'load'
      entry.off 'error'
    entry.on 'error', (err) ->
      callback err, null


module.exports = Importer