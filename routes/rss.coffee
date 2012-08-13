RSS       = require 'rss'
EntryList = require '../lib/entry-list'
data2www  = require '../lib/data2www'
datapath  = config.get('paths:data')

loadXML = (cb) ->
  options =
    limit: 20
  EntryList.load datapath, options, (err, list) ->
    throw err if err

    feed = new RSS
      title:        "Miliam Jorde"
      description:  "En berättelse om ett barns uppväxt"
      feed_url:     "http://miliam.se/rss.xml"
      site_url:     "http://miliam.se"
      image_url:    "http://miliam.se/favicon.png"

    for entry in list.entries
      imgs =  unless entry.images
                []
              else
                console.dir entry.images
                "<img src='http://miliam.se#{data2www image.w640}?ref=feed'>" for image in entry.images

      feed.item
        title:        entry.title
        description:  "#{imgs.join ''}#{entry.html}"
        url:          entry.url
        date:         entry.time.toString()

    cb feed.xml(true)


module.exports = (req, res) ->
  loadXML (xml) ->
    res.set 'Content-Type', 'application/rss+xml; charset=utf-8'
    res.send 200, xml