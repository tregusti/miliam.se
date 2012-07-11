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
  deferred = Q.defer()

  # check if we already have time set
  if entry.time
    # if so resolve directly
    deferred.resolve()
    # and return immediately
    return deferred.promise

  # else fetch time from images
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

  ok = (times) ->
    time = times.sort().pop() # Get earliest date available
    entry.time = time
    deferred.resolve()
  fail = (err) ->
    throw err

  promises = (parser image for image in entry.images or [])
  Q.all(promises).then ok, fail

  # end return promise
  deferred.promise



eventuallySerializeEntry = (entry) ->
  deferred = Q.defer()
  deferred.reject new Error("No date time available for entry") unless entry.time

  # Update base path with new data
  entry.basepath = Path.join '/tmp', 'data', entry.datePath, entry.slug

  mkdirp = require 'mkdirp'
  mkdirp entry.basepath, (err) ->
    throw err if err
    deferred.resolve()

  deferred.promise


Importer =
  import: (entry, basepath, callback) ->
    # Ensure we got an entry to import
    throw new ArgumentError 'entry', entry unless entry instanceof Entry

    eventuallyResolveImages(entry).then(->
      eventuallySetDateFromImages(entry).then(->
        eventuallySerializeEntry(entry).then(->
          callback null if callback instanceof Function
        ).end()
      ).end()
    ).end()



module.exports = Importer