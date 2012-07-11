fs = require("fs")
Path = require("path")

sprintf = require('sprintf').sprintf
marked = require 'marked'

Guard = require("./guard")

log = require('./log') 'Entry'

# getImageDate = (path, callback) ->
#   gm(path).identify (err, identity) ->
#     date = identity?['Profile-EXIF']?['Date Time Original'] || null
#     # graphicsmagick uses bad format for dates: YYYY:MM:DD HH:MM:SS
#     # date separator should be '-', not ':'
#     if date
#       date = date.replace /^(\d\d\d\d):(\d\d):(\d\d) (\d\d):(\d\d):(\d\d)/, '$1-$2-$3 $4:$5:$6'
#       date = new Date date
#     callback date

class Entry
  constructor: ->
    @basepath = null
    @title = null
    @text = null
    @time = null
    @images = null

  serialize: ->
    if @time
      date = sprintf "%04d-%02d-%02d", @time.getFullYear(), @time.getMonth()+1, @time.getDate()
      time = sprintf "%02d:%02d:%02d", @time.getHours(), @time.getMinutes(), @time.getSeconds()
    a = []
    a.push "title: #{@title}" if @title
    a.push "date: #{date}" if date
    a.push "time: #{time}" if time
    a.push "image: #{image.original.match(/^(.*?)(\.original)?\.jpg/)[1]}" for image in @images when image.original if @images
    a.push "\n#{@text}" if @text
    a.join '\n'


Object.defineProperty Entry::, 'html',
  enumerable: true,
  get: ->
    return null unless @text
    marked @text

Object.defineProperty Entry::, 'datePath',
  enumerable: true,
  get: ->
    return null unless @time
    return sprintf '%04d/%02d/%02d', @time.getFullYear(), @time.getMonth() + 1, @time.getDate()

Object.defineProperty Entry::, 'slug',
  enumerable: true,
  get: ->
    return null unless @title
    require('slug') @title.toLowerCase()

Object.defineProperty Entry::, 'humanTime',
  enumerable: true,
  get: ->
    return null unless @time
    sprintf "%2d:%2d", @time.getHours(), @time.getMinutes()

Object.defineProperty Entry::, 'humanDate',
  enumerable: true,
  get: ->
    return null unless @time
    months = "jan feb mar apr maj jun jul aug sep okt nov dec".split " "
    sprintf "%d %s %d", @time.getDate(), months[@time.getMonth()], @time.getFullYear()




parseContents = (entry, contents) ->
  chunks = contents.split '\n\n'

  meta = {}
  for line in chunks.shift().split('\n')
    m = line.match /^(\w+):\s*(.+)$/
    if m
      if m[1] is 'image'
        meta[m[1]] ?= []
        meta[m[1]].push createImageObject(entry.basepath, m[2])
      else
        meta[m[1]] = m[2]

  entry.text = chunks.join('\n\n') or null
  entry.title = meta.title if 'title' of meta
  entry.images = meta.image if 'image' of meta
  # Special treatment for datetime
  if 'time' of meta
    if 'date' of meta
      today = meta.date
    else
      today = new Date().toISOString().substr(0,10)
    entry.time = new Date "#{today} #{meta.time}"
  else
    entry.time = null


createImageObject = (base, name) ->
  o = {}
  o[size] = Path.join base, "#{name}.#{size}.jpg" for size in ['original', 'w320', 'w640', 'w1024']
  o


Entry.load = (path, options, callback) ->
  Guard.string "path", path
  log.debug "Loading #{path}"

  # If no options specified, shift arguments
  [options, callback] = [{}, options] if options instanceof Function

  # Default values
  entry = new Entry
  entry.basepath = path

  # Load up contents
  path = Path.join entry.basepath, 'info.txt'
  fs.readFile path, 'utf8', (err, contents) ->
    # Errors?
    callback err, null if err
    callback new Error("Not valid contents in #{path}"), null unless contents

    log.debug "File loaded: #{contents} #{err}"
    parseContents entry, contents

    callback null, entry

module.exports = Entry