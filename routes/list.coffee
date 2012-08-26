EntryList     = require '../lib/entry-list'
NotFoundError = require '../lib/errors/notfound'

module.exports = (req, res, next) ->
  [year, month, date, page] = req.params
  layout = not req.xhr

  page = page | 0 or 1 # to int and default 1
  limit = config.get 'list:count'

  opts =
    year   : year
    month  : month
    date   : date
    offset : (page - 1) * limit
    limit  : limit

  EntryList.load config.get('paths:data'), opts, (err, list) ->

    if err
      next new NotFoundError req.path
    else
      layout = if layout then "list" else "list_"
      res.render layout,
        title: list.title
        entries: list.entries