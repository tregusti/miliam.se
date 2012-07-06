Path = require 'path'
Entry = require '../entry'

Q = require 'q'

ArgumentError = require '../errors/argument'
# log = require('../log') "Importer"

cp = require('child_process')


generateImage = (path, size) ->
  out = path.replace /\.jpg$/, ".w#{size}.jpg"
  cmd = "/usr/local/bin/gm convert
          -size #{size}x#{size}
          #{path}
          -resize #{size}x#{size}
          #{out} && echo '#{out}'"
  # create promise and return it
  # see: https://github.com/kriskowal/q/#adapting-node
  Q.ninvoke cp, 'exec', cmd

generateImages = (path) ->
  deferred = Q.defer()

  ok = (paths) ->
    deferred.resolve
      w320: paths[0]
      w640: paths[1]
      w1024: paths[2]

  fail = (err) ->
    deferred.reject err

  Q.all([
    generateImage(path, 320),
    generateImage(path, 640),
    generateImage(path, 1024)
  ]).then ok, fail

  deferred.promise

Importer =
  load: (path, callback) ->
    return callback new ArgumentError('path', path), null unless path
    Entry.load path, (err, entry) ->
      return callback err, null if err

      cp.exec "find -L #{entry.basepath} -regex '.*\/.*.jpg$'", (err, str) ->
        return callback err, null if err

        invokations = (generateImages file for file in str.split '\n' when file?)

        ok = (images) ->
          entry.images = images if Object.keys(images).length > 0
          callback null, entry

        fail = (err) ->
          callback err, null

        Q.all(invokations).then ok, fail



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