Path = require "path"
express = require "express"
routes = require "./routes"
http = require "http"
stylus = require 'stylus'
nib = require 'nib'
util = require 'util'

NotFoundError = require './lib/errors/notfound'

stylusMiddleware = ->
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
    compress: false,
    debug: true,
    force: true

errorHandler = (err, req, res, next) ->
  # if an error occurs Connect will pass it down
  # through these "error-handling" middleware
  # allowing you to respond however you like
  if err instanceof NotFoundError
    res.render '404.jade',
      title: '404 bebisar borta'
      status: 404
  else
    res.render '500.jade',
      status: 500
      title: 'Nu blev det fel'

app = express()
app.configure ->
  app.set "port", process.env.PORT or 3000
  app.set "views", __dirname + "/views"
  app.set "view engine", "jade"
  app.use express.favicon()
  app.use express.logger("dev")
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use stylusMiddleware()
  app.use express.static __dirname + "/public"
  app.use app.router
  app.use errorHandler


app.configure "development", ->
  app.use express.errorHandler()


require('./lib/age').attach app

app.locals.use (req, res) ->
  res.locals.data2www = (path) ->
    datapath = Path.join __dirname, 'data'
    path = Path.resolve path
    if path.substr(0, datapath.length) is not datapath
      throw new Error 'Path not inside data path'
    path.substr datapath.length


# routes
app.get ///^
  (/(\d\d\d\d)
    (/(\d\d)
      (/(\d\d))?
    )?
  )?
  /?
  $///, routes.list
app.get /^\/(\d\d\d\d)\/(\d\d)\/(\d\d)\/([\w-]+)$/, routes.entry
app.get /^\/(\d\d\d\d)\/(\d\d)\/(\d\d)\/([\w-]+)\/(original|normal|thumb)\.jpg$/, routes.entryImage
app.get "/", routes.index
app.get "/*", (req, res) -> throw new NotFoundError

http.createServer(app).listen app.get("port"), ->
  console.log "Express server listening on port " + app.get("port")