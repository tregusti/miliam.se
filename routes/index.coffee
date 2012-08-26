Path = require 'path'
fs = require 'fs'

files = (Path.basename file, '.coffee' for file in fs.readdirSync __dirname)
exports[name] = require "./#{name}" for name in files when name isnt "index"