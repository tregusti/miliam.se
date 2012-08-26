Path  = require 'path'
Entry = require '../lib/entry'

module.exports = (req, res, next) ->
  [year, month, date, slug] = req.params
  path  = Path.join(config.get('paths:data'), year, month, date, slug)
  entry = Entry.load path, (err, entry) ->
    throw err if err
    res.render "entry",
      entry       : entry
      url         : entry.url
      title       : entry.title
      description : entry.description