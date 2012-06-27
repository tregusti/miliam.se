fs = require("fs")
Path = require("path")

sprintf = require('sprintf').sprintf

ArgumentError = require("./errors/argument")
Observable = require("observables").Observable
Guard = require("./guard")
EntryInfoSerializer = require("./entry-info-serializer")

class Entry extends Observable
  constructor: (path) ->
    super
    Guard.string "path", path
    entry = this
    fs.readFile Path.join(path, "info.txt"), "utf8", (err, data) ->
      return if err
      EntryInfoSerializer.deserialize entry, data
      entry.fire "load"

Object.defineProperty Entry::, 'humanTime',
  get: ->
    return null unless @time
    sprintf "%2d:%2d", @time.getHours(), @time.getMinutes()

Object.defineProperty Entry::, 'humanDate',
  get: ->
    return null unless @time
    months = "jan feb mar apr maj jun jul aug sep okt nov dec".split " "
    sprintf "%d %s %d", @time.getDate(), months[@time.getMonth()], @time.getFullYear()

module.exports = Entry