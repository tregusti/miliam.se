RSS = require 'rss'

EntryList = require '../lib/entry-list'

datapath = config.get('paths:data')

loadXML = (cb) ->
  EntryList.load datapath, {}, (err, entries) ->
    throw err if err

    feed = new RSS
      title:        "Miliam Jorde"
      description:  "En berättelse om ett barns uppväxt"
      feed_url:     "http://miliam.se/rss.xml"
      site_url:     "http://miliam.se"
      image_url:    "http://miliam.se/favicon.png"

    for entry in entries
      feed.item
        title:        entry.title
        description:  entry.html
        url:          "http://miliam.se/2012/something/#{entry.slug}"
        date:         entry.time.toString()

    cb feed.xml(true)


module.exports = (req, res) ->
  loadXML (xml) ->
    res.send 200, xml