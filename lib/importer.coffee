Path = require 'path'
Q = require 'q'

Entry = require './entry'
ArgumentError = require './errors/argument'
log = require('./log') 'Importer'

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

eventuallyCreateFolder = (entry) ->
  deferred = Q.defer()

  basepath = Path.join config.get('paths:data'), entry.datePath, entry.slug

  mkdirp = require 'mkdirp'
  mkdirp basepath, (err) ->
    throw err if err

    entry.basepath = basepath
    deferred.resolve()

  deferred.promise

eventuallySerializeEntry = (entry) ->
  deferred = Q.defer()

  deferred.reject new Error("No date time available for entry") unless entry.time

  require('fs').writeFile Path.join(entry.basepath, 'info.txt'), entry.serialize(), (err) ->
    throw err if err
    deferred.resolve()

  deferred.promise


eventuallyGenerateImages = (entry) ->
  deferred = Q.defer()
  gm = require 'gm'

  generate = (image, size) ->
    promises = (for size in [320, 640, 960]
      from = Path.join config.get('paths:create'), image.original
      to = Path.join entry.basepath, image.original.replace /\.jpg$/, ".w#{size}.jpg"
      proxy = gm(from).resize(size, size)
      Q.ncall proxy.write, proxy, to
    )

    Q.all promises

  promises =  if entry.images and entry.images.length > 0
                (generate image for image in entry.images)
              else
                []

  Q.all promises

eventuallyMoveImages = (entry) ->
  fs = require 'fs'
  files = if entry.images?.length > 0
            image.original for image in entry.images
          else
            []

  mover = (file) ->
    from = Path.join config.get('paths:create'), file
    to = Path.join entry.basepath, file
    Q.ninvoke fs, 'rename', from, to

  Q.all (mover file for file in files)


Importer =
  import: (entry, basepath, callback) ->
    # Ensure we got an entry to import
    throw new ArgumentError 'entry', entry unless entry instanceof Entry

    eventuallyResolveImages(entry)
      .then ->
        eventuallySetDateFromImages(entry)
      .then ->
        eventuallyCreateFolder(entry)
      .then ->
        eventuallyGenerateImages(entry)
      .then ->
        eventuallySerializeEntry(entry)
      .then ->
        eventuallyMoveImages(entry)
      .then ->
        callback null if callback instanceof Function
      .end()



module.exports = Importer