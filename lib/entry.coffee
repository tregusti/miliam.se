fs = require("fs")
Path = require("path")

sprintf = require('sprintf').sprintf
marked = require 'marked'

Guard = require("./guard")

log = require('./log') 'Entry'

defineGetters = (entry) ->
  Object.defineProperty entry, 'html',
    enumerable: true,
    get: ->
      return null unless @text
      marked @text

  Object.defineProperty entry, 'humanTime',
    enumerable: true,
    get: ->
      return null unless @time
      sprintf "%2d:%2d", @time.getHours(), @time.getMinutes()

  Object.defineProperty entry, 'humanDate',
    enumerable: true,
    get: ->
      return null unless @time
      months = "jan feb mar apr maj jun jul aug sep okt nov dec".split " "
      sprintf "%d %s %d", @time.getDate(), months[@time.getMonth()], @time.getFullYear()

# imagePaths = (entry) ->
#   original : Path.join(entry.path, "original.jpg"),
#   normal   : Path.join(entry.path, "normal.jpg"),
#   thumb    : Path.join(entry.path, "thumb.jpg")
#
# hasAllImages = (entry, callback) ->
#   paths = imagePaths entry
#   Path.exists paths.normal, (exists) ->
#     return callback false unless exists
#     Path.exists paths.original, (exists) ->
#       return callback false unless exists
#       Path.exists paths.thumb, (exists) ->
#         return callback false unless exists
#         callback true

# getImageDate = (path, callback) ->
#   gm(path).identify (err, identity) ->
#     date = identity?['Profile-EXIF']?['Date Time Original'] || null
#     # graphicsmagick uses bad format for dates: YYYY:MM:DD HH:MM:SS
#     # date separator should be '-', not ':'
#     if date
#       date = date.replace /^(\d\d\d\d):(\d\d):(\d\d) (\d\d):(\d\d):(\d\d)/, '$1-$2-$3 $4:$5:$6'
#       date = new Date date
#     callback date

# class Entry
#   constructor: ->
    # super
    # Guard.string "path", path
    # entry = this
    # @path = path
    # fs.readFile Path.join(path, "info.txt"), "utf8", (err, data) ->
    #   return entry.fire 'error', err if err
    #
    #   EntryInfoSerializer.deserialize entry, data
    #   defineGetters entry
    #   hasAllImages entry, (exists) ->
    #     entry.image = null
    #     entry.image = imagePaths entry if exists
    #     if entry.time is null
    #       getImageDate entry.image.original, (date) ->
    #         entry.time = if date then date else new Date
    #         entry.fire "load"
    #     else
    #       entry.fire "load"

load = (path, options, callback) ->
  Guard.string "path", path
  log.debug "Loading #{path}"

  [options, callback] = [{}, options] if options instanceof Function

  entry =
    basepath: path
    images: null
    title: null
    time: null
    text: null

  path = Path.join entry.basepath, 'info.txt'
  fs.readFile path, 'utf8', (err, contents) ->
    console.dir ['ojjj', err] if err
    callback err, null if err
    callback new Error("Not valid contents in #{path}"), null unless contents
    log.debug "File loaded: #{contents} #{err}"

    chunks = contents.split '\n\n'
    meta = chunks
              .shift()
              .split('\n')
              .reduce ((meta, line) ->
                m = line.match /^(\w+):\s*(.+)$/
                meta[m[1]] = m[2] if m
                meta), {}

    entry.text = chunks.join('\n\n') or null
    entry.title = meta.title if 'title' of meta

    if 'time' of meta
      if 'date' of meta
        today = meta.date
      else
        today = new Date().toISOString().substr(0,10)
      entry.time = new Date "#{today} #{meta.time}"
    else
      entry.time = null


    defineGetters entry
    callback null, entry

module.exports.load = load