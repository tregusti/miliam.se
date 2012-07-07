cp = require 'child_process'
Path = require 'path'
util = require 'util'

sprintf = require('sprintf').sprintf
Q = require 'q'

Entry = require '../entry'
ArgumentError = require '../errors/argument'

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

moveImages = (entry, to) ->
  deferred = Q.defer()

  ok = (errs) ->
    debugger
    return deferred.reject(err) for err in errs when err
    deferred.resolve()

  fail = (err) ->
    deferred.reject err

  fs = require 'fs'
  imgs = []
  imgs.push path for size, path of imgset for imgset in entry.images
  Q
    .all(Q.ninvoke fs, 'rename', img, Path.join(to, Path.basename(img)) for img in imgs)
    .then(ok, fail)

  deferred.promise


Importer =
  load: (path, callback) ->
    return callback new ArgumentError('path', path), null unless path
    Entry.load path, (err, entry) ->
      return callback err, null if err

      cp.exec "find -L #{entry.basepath} -regex '.*\/.*.jpg$'", (err, str) ->
        return callback err, null if err

        invokations = (generateImages file for file in str.trim().split '\n' when file?)

        ok = (images) ->
          entry.images = images if Object.keys(images).length > 0
          callback null, entry

        fail = (err) ->
          callback err, null

        Q.all(invokations).then ok, fail

  import: (entry, basepath, callback) ->
    # require here, to allow mocking in specs
    mkdirp = require 'mkdirp'
    fs = require 'fs'


    date = sprintf '%04d/%02d/%02d', entry.time.getFullYear(), entry.time.getMonth() + 1, entry.time.getDate()

    path = Path.join basepath, date, entry.slug

    mkdirp path, (err) ->
      return callback err, null if err
      fs.writeFile Path.join(path, 'info.txt'), entry.serialize(), 'utf8', (err) ->
        return callback err, null if err

        moveImages(entry, path).then (err) ->
          return callback err if err
          callback null



module.exports = Importer