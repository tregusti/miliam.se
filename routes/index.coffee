Path = require 'path'
express = require 'express'
fs = require 'fs'
marked = require 'marked'

Entry = require '../lib/entry'
EntryList = require '../lib/entry-list'
NotFoundError = require '../lib/errors/notfound'

datapath = config.get 'paths:data'

files = (Path.basename file, '.coffee' for file in fs.readdirSync __dirname)
exports[name] = require "./#{name}" for name in files when name isnt "index"