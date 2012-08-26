EntryList     = require '../lib/entry-list'
NotFoundError = require '../lib/errors/notfound'

module.exports = (req, res, next) ->
  [year, month, date, page] = req.params
  json = req.xhr

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
      view = if json then "list_" else "list"
      data =
        title: list.title
        entries: list.entries
      res.render view, data, (err, html) ->
        if json
          res.json
            html: html
            more: list.more
        else
          res.send html