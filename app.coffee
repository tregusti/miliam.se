express = require "express"
routes = require "./routes"
http = require "http"

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
  app.use express.static(__dirname + "/public")

app.configure "development", ->
  app.use express.errorHandler()


Age = require './lib/age'
birth = new Date '2012-06-06 19:30:00'

app.locals.use (req, res) ->
  res.locals.humanAge = Age.since birth


# routes
app.get /^\/(\d\d\d\d)\/(\d\d)\/([\w-]+)$/, routes.entry
app.get "/", routes.index


http.createServer(app).listen app.get("port"), ->
  console.log "Express server listening on port " + app.get("port")