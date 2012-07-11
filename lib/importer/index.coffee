# cp = require 'child_process'
Path = require 'path'
# util = require 'util'
#
# sprintf = require('sprintf').sprintf
Q = require 'q'
#
Entry = require '../entry'
ArgumentError = require '../errors/argument'

log = require('../log') 'Importer'

# generateImage = (path, size) ->
#   out = path.replace /\.jpg$/, ".w#{size}.jpg"
#   cmd = "/usr/local/bin/gm convert
#           -size #{size}x#{size}
#           #{path}
#           -resize #{size}x#{size}
#           #{out} && echo '#{out}'"
#   # create promise and return it
#   # see: https://github.com/kriskowal/q/#adapting-node
#   Q.ninvoke cp, 'exec', cmd
#
# generateImages = (original) ->
#   deferred = Q.defer()
#
#   ok = (paths) ->
#     # Why is the next line needed when running for real? Remove and add spec!
#     # Every other line seems to be a blank line.
#     paths = (path.trim() for path in paths when path.trim())
#     deferred.resolve
#       original: original
#       w320: paths[0]
#       w640: paths[1]
#       w1024: paths[2]
#
#   fail = (err) ->
#     deferred.reject err
#
#   Q.all([
#     generateImage(original, 320),
#     generateImage(original, 640),
#     generateImage(original, 1024)
#   ]).then ok, fail
#
#   deferred.promise
#
# moveImages = (entry, to) ->
#   deferred = Q.defer()
#
#   ok = (errs) ->
#     for err in errs when err
#       log.error "Error moving image: #{err.message}"
#       return deferred.reject(err)
#     deferred.resolve()
#     log.info "Image files move ok"
#
#   fail = (err) ->
#     log.error "Error moving image: #{err.message}"
#     deferred.reject err
#
#   fs = require 'fs'
#   imgs = []
#   imgs.push path for size, path of imgset for imgset in entry.images
#
#   filename = (old) ->
#     base = Path.basename(img)
#     base = base.replace /\.jpg$/, '.original.jpg' unless /\.w\d+\.jpg$/.test base
#     Path.join to, base
#
#   Q
#     .all(Q.ninvoke fs, 'rename', img, filename(img) for img in imgs)
#     .then(ok, fail)
#
#   deferred.promise

eventuallyResolveImages = (entry) ->
  from = Path.resolve entry.basepath
  deferred = Q.defer()

  images = []

  finder = require('findit').find from
  finder.on 'file', (file, stat) ->
    images.push file if Path.extname(file) is '.jpg'
  finder.on 'end', ->
    if images.length
      entry.images = []
      entry.images.push original: Path.basename(image) for image in images
    deferred.resolve()
  deferred.promise



eventuallySetDateFromImages = (entry) ->
  gm = require 'gm'
  parser = (image) ->
    local = Q.defer()
    gm(image.original).identify (err, info) ->
      local.reject err if err
      time = info?['Profile-EXIF']?['Date Time Original'] or null
      if time
        time = time.replace /^(\d\d\d\d):(\d\d):(\d\d) (\d\d):(\d\d):(\d\d)/, '$1-$2-$3 $4:$5:$6'
        time = new Date time
      local.resolve time
    local.promise

  deferred = Q.defer()
  ok = (times) ->
    time = times.sort().pop()
    entry.time = time
    deferred.resolve()
  fail = (err) ->
    throw err

  promises = (parser image for image in entry.images or [])
  Q.all(promises).then ok, fail

  deferred.promise

Importer =
  import: (entry, basepath, callback) ->
    # Ensure we got an entry to import
    throw new ArgumentError 'entry', entry unless entry instanceof Entry

    eventuallyResolveImages(entry).then(->
      eventuallySetDateFromImages(entry).then(->
        # console.dir [entry, arguments, callback instanceof Function]
        callback null if callback instanceof Function
      ).end()
    ).end()
    return

    # require here, to allow mocking in specs
    mkdirp = require 'mkdirp'
    fs = require 'fs'


    date = sprintf '%04d/%02d/%02d', entry.time.getFullYear(), entry.time.getMonth() + 1, entry.time.getDate()

    path = Path.join basepath, date, entry.slug

    mkdirp path, (err) ->
      return callback err, null if err

      log.info "Ensured path to new entry exists: #{path}"
      #
      # loadImages...
      #
      # loadDateFromImage
      #
      # all ok?
      #
      # generateImages
      #
      # fs.writeFile Path.join(path, 'info.txt'), entry.serialize(), 'utf8', (err) ->
      #   return callback err, null if err
      #
      #   log.info "Wrote to new info.txt file"
      #
      #   moveImages(entry, path).then (err) ->
      #     return callback err if err
      #     callback null



module.exports = Importer