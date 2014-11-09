ArgumentError = require '../errors/argument'
Path = require 'path'

log = require('../log') 'Image generator'

exports.generate = (path, outpath, callback) ->
  return callback new ArgumentError 'path' unless path
  return callback new ArgumentError 'outpath' unless outpath

  basename = Path.basename path.toLowerCase(), '.jpg'

  f = (w, cb) ->
    file = Path.join outpath, "#{basename}.w#{w}.jpg"
    log.debug "Try read '#{file}' from disk"
    gm = require('gm')(path).autoOrient()
    log.debug "Did read '#{file}' from disk"
    log.debug "Try write '#{file}' to disk"
    gm.resize(w, null, '^').write file, (err) ->
      throw err if err
      log.debug "Did write '#{file}' to disk"
      cb()
  try
    f 320, ->
      f 640, ->
        f 960, ->
          callback null
  catch err
    log.error "Could not write to disk: #{err}"
    callback err, null
