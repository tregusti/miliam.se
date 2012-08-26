EntryList     = require '../lib/entry-list'
NotFoundError = require '../lib/errors/notfound'

module.exports = (req, res, next) ->
  [year, month, date] = req.params
  opts = year: year, month: month, date: date
  EntryList.load config.get('paths:data'), opts, (err, list) ->

    if err
      next new NotFoundError req.path
    else
      res.render "list",
        title: list.title
        entries: list.entries
