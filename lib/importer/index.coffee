Path = require 'path'
util = require 'util'
Q = require 'q'

Entry = require '../entry'
ArgumentError = require '../errors/argument'
InvalidStateError = require '../errors/invalidstate'
log = require('../log') 'Importer'

TEMPLATE = "
title: Ändra mig\n
\n
Lite exempeltext. Brödtexten börjar 2 radbrytningar efter title etc ovanför.
"

# IMPORT

eventuallyResolveImages = (entry) ->
  log.debug 'Begin finding images for entry'

  from = Path.resolve entry.basepath
  deferred = Q.defer()

  images = []

  finder = require('findit').find from
  finder.on 'file', (file, stat) ->
    images.push file if /^\.jpg$/i.test(Path.extname(file))
  finder.on 'end', ->
    if images.length
      entry.images = []
      f = (image) ->
        o =
          original: Path.basename(image).toLowerCase()
          imported: Path.basename(image)
        entry.images.push o
      f image for image in images
    deferred.resolve()
  deferred.promise



eventuallySetDateFromImages = (entry) ->
  deferred = Q.defer()
  return deferred.resolve() if entry.time

  log.debug 'Begin looking up dates in images'

  gm = require 'gm'

  parse = (image) ->
    path = Path.join config.get('paths:create'), image.imported
    local = Q.defer()
    gm(path).identify (err, info) ->
      local.reject err if err
      time = info?['Profile-EXIF']?['Date Time Original'] or null
      if time
        time = time.replace /^(\d\d\d\d):(\d\d):(\d\d) (\d\d):(\d\d):(\d\d)/, '$1-$2-$3 $4:$5:$6'
        time = new Date time
      local.resolve time
    local.promise

  promises = (parse image for image in entry.images or [])

  Q.all(promises).then (times) ->
    if time = times.sort().pop() # Get earliest date available
      log.debug "Found time in images: #{time}"
      entry.time = time
      deferred.resolve()
    else
      deferred.reject new Error 'No time available in EXIF data of image, please specify date and time in info.txt.'

  deferred.promise



eventuallyCreateFolder = (entry) ->
  log.debug 'Begin creating folder in data structure'
  deferred = Q.defer()

  basepath = Path.join config.get('paths:data'), entry.datePath, entry.slug

  mkdirp = require 'mkdirp'
  mkdirp basepath, (err) ->
    deferred.reject err if err

    entry.basepath = basepath
    deferred.resolve()

  deferred.promise

eventuallySerializeEntry = (entry) ->
  log.debug 'Begin Saving entry metadata to info.txt'
  deferred = Q.defer()

  throw new Error("No date time available for entry") unless entry.time

  require('fs').writeFile Path.join(entry.basepath, 'info.txt'), entry.serialize(), (err) ->
    deferred.reject err if err
    deferred.resolve()

  deferred.promise


eventuallyGenerateImages = (entry) ->
  log.debug 'Begin generating sized images'
  Generator = require "./image-generator"

  promises = []
  if entry.images?.length > 0
    for image in entry.images
      from    = Path.join config.get('paths:create'), image.imported
      promises.push Q.ncall Generator.generate, null, from, entry.basepath

  Q.all promises

eventuallyMoveImages = (entry) ->
  log.debug 'Begin moving original images to data structure'
  fs = require 'fs'
  files = if entry.images?.length > 0
            image.imported for image in entry.images
          else
            []

  mover = (file) ->
    from = Path.join config.get('paths:create'), file
    to = Path.join entry.basepath, file.toLowerCase()
    Q.ninvoke fs, 'rename', from, to

  Q.all (mover file for file in files)

eventuallyRemoveOkFolder = ->
  log.debug 'Begin removing ok folder'
  path = Path.join config.get('paths:create'), 'ok'
  fs = require 'fs'
  Q.ncall fs.rmdir, fs, path


eventuallyWriteTemplate = ->
  log.debug 'Begin writing template file to create structure'
  path = Path.join config.get('paths:create'), 'info.txt'
  fs = require 'fs'
  Q.ncall fs.writeFile, fs, path, TEMPLATE



# CHECK

checkForOkFolder = ->
  deferred = Q.defer()

  exists = null
  finder = require('findit').find config.get 'paths:create'
  finder.on 'directory', (dir, stat) ->
    exists = dir if Path.basename(dir) is 'ok'
  finder.on 'end', ->
    if exists
      deferred.resolve exists
    else
      deferred.reject new InvalidStateError("No 'ok' folder present")

  deferred.promise




Importer =
  import: (entry, basepath, callback) ->
    log.info 'Begin importing entry'

    callback ||= ->

    # Ensure we got an entry to import
    throw new ArgumentError 'entry', entry unless entry instanceof Entry

    eventuallyResolveImages(entry)
      .then( eventuallySetDateFromImages .bind null, entry )
      .then( eventuallyCreateFolder      .bind null, entry )
      .then( eventuallyGenerateImages    .bind null, entry )
      .then( eventuallySerializeEntry    .bind null, entry )
      .then( eventuallyMoveImages        .bind null, entry )
      .then( eventuallyRemoveOkFolder                      )
      .then( eventuallyWriteTemplate                       )

      .then ->
        log.info 'Entry imported ok'
        callback null

      .fail (err) ->
        log.error 'Entry import error: ' + util.inspect err
        eventuallyRemoveOkFolder().then ->
          callback err

      .end()

  check: (callback) ->
    checkForOkFolder()
      .then (dir) ->
        log.info "Checker says ok"
        callback null
      .fail (err) ->
        log.error "Checker rejects: #{err.message}"
        callback err
      .end()

module.exports = Importer