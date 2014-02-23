fs   = require("fs")
Path = require("path")

sprintf = require('sprintf').sprintf
Q       = require 'q'

Guard     = require "./guard"
generator = require './html-generator'
age       = require "./age"
log       = require('./log') 'Entry'

require '../public/js/augment'

class Entry
  constructor: ->
    @basepath = null
    @title = null
    @text = null
    @time = null
    @videos = null
    @images = null
    @type = 'post'

  serialize: ->
    throw new Error "A title is required" unless @title
    if @time
      date = sprintf "%04d-%02d-%02d", @time.getFullYear(), @time.getMonth()+1, @time.getDate()
      time = sprintf "%02d:%02d:%02d", @time.getHours(), @time.getMinutes(), @time.getSeconds()
    a = []
    a.push "title: #{@title}"
    a.push "date: #{date}" if date
    a.push "time: #{time}" if time
    a.push "type: #{@type}"
    a.push "image: #{image.original.match(/^(.*?)(\.original)?\.jpg/i)[1]}" for image in @images when image.original if @images
    a.push "video: #{video.id} r=#{video.ratio}" for video in @videos if @videos
    a.push "\n#{@text}" if @text
    a.join '\n'


Object.defineProperty Entry::, 'html',
  enumerable: true,
  get: ->
    return null unless @text
    generator @text

Object.defineProperty Entry::, 'subtitle',
  enumerable: true,
  get: ->
    return null unless @time
    from = new Date(age.birth)
    to   = @time
    s    = age.between from, to
    if from <= to
      "#{s} gammal"
    else
      "#{s} till födseln"

Object.defineProperty Entry::, 'description',
  enumerable: true,
  get: ->
    t = @html
    return null unless t
    t = t.replace /<.+?>/g, '' # html
    t = t.trim().replace /\s\s/g, ' ' # white space
    t[0..99]

Object.defineProperty Entry::, 'datePath',
  enumerable: true,
  get: ->
    return null unless @time
    return sprintf '%04d/%02d/%02d', @time.getFullYear(), @time.getMonth() + 1, @time.getDate()

Object.defineProperty Entry::, 'path',
  enumerable: true,
  get: ->
    return null unless @time and @datePath
    return "/#{@datePath}/#{@slug}"

Object.defineProperty Entry::, 'url',
  enumerable: true,
  get: ->
    return null unless @path
    return "http://miliam.se#{@path}"

Object.defineProperty Entry::, 'slug',
  enumerable: true,
  get: ->
    return null unless @title
    ###
    These are the chars that node-slug module doesn't replace.
    See: https://github.com/dodo/node-slug/blob/0aeba61e4df3708c40f9ea859e6b90bbab4c5813/src/slug.coffee#L87
    and  https://github.com/dodo/node-slug/blob/0aeba61e4df3708c40f9ea859e6b90bbab4c5813/test/slug.test.coffee#L17
    ###
    re = /// [
      \*
      \+
      \.
      \(
      \)
      \\
      !
      :
      @
      '
      "
      ~
    ] ///g
    require('slug') @title.toLowerCase().replace re, ''

Object.defineProperty Entry::, 'humanTime',
  enumerable: true,
  get: ->
    return null unless @time
    sprintf "%02d:%02d", @time.getHours(), @time.getMinutes()

Object.defineProperty Entry::, 'humanDate',
  enumerable: true,
  get: ->
    return null unless @time
    months = "jan feb mar apr maj jun jul aug sep okt nov dec".split " "
    sprintf "%d %s %d", @time.getDate(), months[@time.getMonth()], @time.getFullYear()




parseContents = ( entry, contents, done ) ->
  chunks = contents.split '\n\n'

  meta = {}
  for line in chunks.shift().split('\n')
    m = line.match /^(\w+):\s*(.+)$/
    if m
      if m[1] is 'video'
        meta[m[1]] ?= []
        meta[m[1]].push parseVideoId(m[2])
      else if m[1] is 'image'
        meta[m[1]] ?= []
        meta[m[1]].push createImageObject(entry.basepath, m[2])
      else
        meta[m[1]] = m[2]

  entry.text = chunks.join('\n\n') or null
  entry.title = meta.title if 'title' of meta
  entry.images = meta.image if 'image' of meta
  entry.type = "quote" if meta.type is "quote"
  entry.videos = meta.video if 'video' of meta
  # Special treatment for datetime
  if 'time' of meta
    if 'date' of meta
      today = meta.date
    else
      today = new Date().toISOString().substr(0,10)
    entry.time = new Date "#{today} #{meta.time}"
  else
    entry.time = null

  promise = Q.resolve()
  promise = promise.then loadVideoRatio.curry(video) for video in entry.videos when not video.ratio if entry.videos
  promise = promise.then -> done()
  promise.end()



loadVideoRatio = ( video ) ->
  request = require 'request'

  deferred = Q.defer()
  url = "http://www.youtube.com/oembed?url=youtu.be/#{video.id}&format=json"
  request url, (error, response, body) ->
    return deferred.reject error if error
    return deferred.reject new Error "Statuscode #{response.statusCode}" unless response.statusCode is 200
    data = JSON.parse body
    video.ratio = Math.round(1000*(data.width / data.height)) / 1000 # round to 3 decimals
    deferred.resolve()

  deferred.promise

parseVideoId = (input) ->
  if ///^http://youtu\.be/(.*)$///.test(input)
    id: RegExp.$1
  else if ///^http://www\.youtube\.com/watch\?v=(.*?)($|&)///.test(input)
    id: RegExp.$1
  else if ///^(.+?)\s+r=(.+?)$///.test(input)
    id: RegExp.$1
    ratio: parseFloat(RegExp.$2, 10)
  else
    id: input


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
    parseContents entry, contents, (err) ->
      callback err, null if err
      callback null, entry

module.exports = Entry