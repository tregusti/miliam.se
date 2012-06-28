util = require 'util'
fs = require 'fs'
Path = require 'path'

Guard = require '../guard'

Logger = do ->
  PATH = Path.join __dirname, '..', '..', 'importer.log'
  (o) ->
    o = util.inspect o unless typeof o is 'string'
    time = new Date().toISOString()
    fs.appendFile PATH, "#{time}: #{o}"

class Importer
  constructor: (path) ->
    Guard.string path

    fs.readFile path, 'utf8', (err, contents) ->
      if err
        Logger err
        throw err


module.exports = Importer