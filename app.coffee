express = require "express"
routes = require "./routes"
http = require "http"
stylus = require 'stylus'
nib = require 'nib'

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

app = express()
app.configure ->
  app.set "port", process.env.PORT or 3000
  app.set "views", __dirname + "/views"
  app.set "view engine", "jade"
  app.use express.favicon()
  app.use express.logger("dev")
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use app.router
  app.use stylusMiddleware()
  app.use express.static __dirname + "/public"


app.configure "development", ->
  app.use express.errorHandler()

require('./lib/age').attach app

# routes
app.get /^\/(\d\d\d\d)\/(\d\d)\/(\d\d)\/([\w-]+)$/, routes.entry
app.get /^\/(\d\d\d\d)\/(\d\d)\/(\d\d)\/([\w-]+)\/(original|normal|thumb)\.jpg$/, routes.entryImage
app.get "/", routes.index


http.createServer(app).listen app.get("port"), ->
  console.log "Express server listening on port " + app.get("port")