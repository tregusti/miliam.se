Path    = require "path"
express = require "express"
http    = require "http"
stylus  = require 'stylus'
nib     = require 'nib'
util    = require 'util'

require './setup'

NotFoundError = require './lib/errors/notfound'
routes = require "./routes"
log = require('./lib/log') ''

stylusMiddleware = ->
  prod = config.get('env') is 'production'
  compile = (str, path) ->
    stylus(str)
      .set("filename", path)
      .set("compress", true)
      .use(nib())
      .import('nib')

  stylus.middleware
    src: __dirname + '/stylus'
    dest: __dirname + '/public',
    compile: compile,
    compress: not prod,
    debug: not prod,
    force: not prod

errorHandler = (err, req, res, next) ->
  # if an error occurs Connect will pass it down
  # through these "error-handling" middleware
  # allowing you to respond however you like
  if err instanceof NotFoundError
    log.warn "404: #{req.url} REFERRER: #{req.headers.referer or null}"
    res.status 404
    res.render '404.jade',
      title: '404 bebisar borta'
      status: 404
  else
    log.warn "500: #{req.url} REFERRER: #{req.headers.referer or null} ERROR: #{JSON.stringify err}\n#{util.inspect err.stack}"
    res.status 500
    res.render '500.jade',
      status: 500
      title: 'Nu blev det fel'

app = express()
app.configure ->
  app.set "port", config.get 'port'
  app.set "views", __dirname + "/views"
  app.set "view engine", "jade"
  app.use express.compress()
  app.use express.logger("dev")
  app.use express.favicon(__dirname + "/public/favicon.ico")
  app.use express.methodOverride()
  app.use express.bodyParser()
  app.use stylusMiddleware()
  app.use express.static __dirname + "/public"
  app.use app.router
  app.use errorHandler


app.configure "development", ->
  app.use express.errorHandler()


require('./lib/age').attach app

app.locals.use (req, res) ->

  res.locals.analytics   = if config.get('analytics:enabled')
                             config.get('analytics:id')
                            else
                              null
  res.locals.description = 'En pojkes uppväxt i bilder'
  res.locals.url         = 'http://miliam.se/'
  res.locals.title       = ''
  res.locals.subtitle    = ''
  res.locals.navigation  = require('./lib/navigation')
  res.locals.keywords    = require('./lib/keywords').join ', '

  # Sharing
  res.locals.show_fblike = config.get('sharing:facebook')
  res.locals.show_plusone = config.get('sharing:plusone')

  res.locals.data2www = require './lib/data2www'


# routes
app.get ///^
  (?:                 # no capture (but group because of optionality)
    /(\d\d\d\d)       # year
    (?:/(\d\d)        # month
      (?:/(\d\d))?    # optional date
    )?                # optional month
  )?                  # optional year
  (?:/p([1-9]\d*))?   # optional page
  /?                  # We may have a trailing slash
  $///, routes.list
app.get /^\/(\d\d\d\d)\/(\d\d)\/(\d\d)\/([\w-]+)$/, routes.entry
app.get /^\/(\d\d\d\d)\/(\d\d)\/(\d\d)\/([\w-]+)\/.*?\.w(320|640|1024)\.jpg$/, routes.entryImage
app.get "/rss.xml", routes.rss
app.get "/tracker", routes.tracker
app.get "/*", routes.page
app.get "/", routes.index
app.get "*", (req, res) -> throw new NotFoundError req.url

http.createServer(app).listen app.get("port"), ->
  log.info "miliam.se started on port #{app.get("port")} in #{config.get('env')} environment"