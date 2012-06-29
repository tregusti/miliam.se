fs = require("fs")
Path = require("path")

sprintf = require('sprintf').sprintf

ArgumentError = require("./errors/argument")
Observable = require("observables").Observable
Guard = require("./guard")
EntryInfoSerializer = require("./entry-info-serializer")

defineHumanTimes = (entry) ->
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

imagePaths = (entry) ->
  original : Path.join(entry.path, "original.jpg"),
  normal   : Path.join(entry.path, "normal.jpg"),
  thumb    : Path.join(entry.path, "thumb.jpg")

hasAllImages = (entry, callback) ->
  paths = imagePaths entry
  Path.exists paths.normal, (exists) ->
    return callback false unless exists
    Path.exists paths.original, (exists) ->
      return callback false unless exists
      Path.exists paths.thumb, (exists) ->
        return callback false unless exists
        callback true

class Entry extends Observable
  constructor: (path) ->
    super
    Guard.string "path", path
    entry = this
    @path = path
    fs.readFile Path.join(path, "info.txt"), "utf8", (err, data) ->
      return if err

      EntryInfoSerializer.deserialize entry, data
      defineHumanTimes entry
      hasAllImages entry, (exists) ->
        entry.image = null
        entry.image = imagePaths entry if exists
        entry.fire "load"

module.exports = Entry