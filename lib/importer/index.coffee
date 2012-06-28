Guard = require '../guard'

class Importer
  constructor: (path) ->
    Guard.string path

module.exports = Importer