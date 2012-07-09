cp = require 'child_process'
Path = require 'path'
util = require 'util'

sprintf = require('sprintf').sprintf
Q = require 'q'

Entry = require '../entry'
ArgumentError = require '../errors/argument'

log = require('../log') 'Importer'

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

generateImages = (original) ->
  deferred = Q.defer()

  ok = (paths) ->
    # Why is the next line needed when running for real? Remove and add spec!
    # Every other line seems to be a blank line.
    paths = (path.trim() for path in paths when path.trim())
    deferred.resolve
      original: original
      w320: paths[0]
      w640: paths[1]
      w1024: paths[2]

  fail = (err) ->
    deferred.reject err

  Q.all([
    generateImage(original, 320),
    generateImage(original, 640),
    generateImage(original, 1024)
  ]).then ok, fail

  deferred.promise

moveImages = (entry, to) ->
  deferred = Q.defer()

  ok = (errs) ->
    for err in errs when err
      log.error "Error moving image: #{err.message}"
      return deferred.reject(err)
    deferred.resolve()
    log.info "Image files move ok"

  fail = (err) ->
    log.error "Error moving image: #{err.message}"
    deferred.reject err

  fs = require 'fs'
  imgs = []
  imgs.push path for size, path of imgset for imgset in entry.images

  filename = (old) ->
    base = Path.basename(img)
    base = base.replace /\.jpg$/, '.original.jpg' unless /\.w\d+\.jpg$/.test base
    Path.join to, base

  Q
    .all(Q.ninvoke fs, 'rename', img, filename(img) for img in imgs)
    .then(ok, fail)

  deferred.promise


Importer =
  load: (path, callback) ->
    return callback new ArgumentError('path', path), null unless path
    Entry.load path, (err, entry) ->
      return callback err, null if err

      log.info "Import entry loaded ok"
      cp.exec "find -L #{entry.basepath} -regex '.*\/.*\.jpg$'", (err, str) ->
        return callback err, null if err

        invokations = (generateImages file for file in str.trim().split '\n' when file?)

        ok = (images) ->
          log.info "Generated all image sizes ok"
          log.debug util.inspect images
          entry.images = images if Object.keys(images).length > 0
          callback null, entry

        fail = (err) ->
          log.error "Image generation failed: #{err.message}"
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

      log.info "Ensured path to new entry exists: #{path}"

      fs.writeFile Path.join(path, 'info.txt'), entry.serialize(), 'utf8', (err) ->
        return callback err, null if err

        log.info "Wrote to new info.txt file"

        moveImages(entry, path).then (err) ->
          return callback err if err
          callback null



module.exports = Importer