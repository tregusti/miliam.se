Path = require 'path'
fs = require 'fs'

original = fs.readFile
files = {}

enable = ->
  fs.readFile = (path, encoding, callback) ->
    resolvedPath = Path.resolve path
    if resolvedPath of files and encoding is 'utf8'
      callback null, files[resolvedPath]
    else
      original.apply this, arguments

disable = ->
  fs.readFile = original

class FileSystemSpy
  constructor: (path, content) ->
    Object.defineProperty this, 'path',
      enumerable: true,
      writeable: false,
      value: Path.resolve path
    Object.defineProperty this, 'dirname',
      enumerable: true,
      writeable: false,
      value: Path.dirname @path
    Object.defineProperty this, 'filename',
      enumerable: true,
      writeable: false,
      value: Path.basename @path

    files[@path] = content
    enable()

  off: ->
    index = files.indexOf @path
    files.removeAt index if index >= 0
    disable() if files.length is 0
    undefined

module.exports.on = (path, contents) ->
  new FileSystemSpy path, contents

module.exports.off = (spy) ->
  spy.off() if spy instanceof FileSystemSpy
  throw new Error 'Not a a valid fs-spy' if spy
  files = {}
  disable()
  undefined