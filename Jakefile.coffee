fs = require 'fs'
child = require 'child_process'
Path = require 'path'
require 'colors'

require './setup'

Entry = require './lib/entry'

invoke = (tasks) ->
  tasks.forEach (task) ->
    console.log "Invoking #{task.blue}:"
    jake.Task[task].invoke()

spawn = (cmd, args, env, done) ->
  env = CoffeeScript.helpers.merge {}, env or {}
  env = CoffeeScript.helpers.merge process.env, env
  cmd = child.spawn cmd, args, env: env
  cmd.stdout.on 'data', (data) -> process.stdout.write data
  cmd.stderr.on 'data', (data) -> process.stderr.write data
  cmd.on 'exit', done if done?
  cmd


# LIST
desc 'List all available tasks'
task 'default', ->
  console.log "This is the same as running 'jake -T'.\n"
  child.exec 'jake -T', (error, stdout, stderr) ->
    console.log stdout

# RUNNER
namespace 'server', ->
  desc "Start up the server in development mode"
  task 'dev', ->
    spawn "supervisor", "-e js\|jade\|coffee -w routes,views,. app.coffee".split(" "),
      NODE_ENV: 'development'

  desc "Start up the server in production mode"
  task 'prod', ->
    spawn "#{__dirname}/node_modules/coffee-script/bin/coffee", ["#{__dirname}/app.coffee"],
      NODE_ENV: 'production'


# SPECS
runSpecs = (params, reporter, done) ->
  env =
    NODE_ENV: 'test'
  spawn "#{__dirname}/node_modules/mocha/bin/mocha", "
      --colors
      --timeout 200
      --recursive
      --compilers coffee:coffee-script
      --require coffee-script
      --require setup.coffee
      #{params || ''}
      --reporter #{reporter || 'dot'}
      specs
  ".trim().split(/\s+/), env, done

desc 'Run all specs'
task 'specs', (params) ->
  runSpecs()

namespace 'specs', ->
  desc 'Run all specs and pretty print'
  task 'pretty', -> runSpecs null, 'spec'

  desc 'Run specs with debugger'
  task 'debug', ->
    console.log "Running specs and start node-inspector".blue
    runSpecs '--debug-brk', null, ->
      console.log "\nSpecs done, kill inspector".blue
      insp.kill()
    insp = spawn 'node-inspector'

  desc 'Continously run specs watching for file changes'
  task 'watch', -> runSpecs "--watch"


# IMPORT
desc 'Import if needed'
task 'import', ->
  basepath = __dirname + "/data"
  Importer = require './lib/importer'
  Entry.load config.get('paths:create'), (err, entry) ->
    throw err if err

    Importer.import entry, basepath, (err) ->
      throw err if err