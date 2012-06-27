fs = require("fs")
Path = require("path")

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

module.exports = Entry