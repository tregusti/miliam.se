fs = require 'fs'
child = require 'child_process'
require 'colors'

invoke = (tasks) ->
  tasks.forEach (task) ->
    console.log "Invoking #{task.blue}:"
    jake.Task[task].invoke()

spawn = (cmd, args, done) ->
  cmd = child.spawn cmd, args
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
desc "Start up the server"
task "start", ->
  spawn "#{__dirname}/node_modules/coffee-script/bin/coffee", ["#{__dirname}/app.coffee"]

namespace 'start', ->
  desc "Start a self-resarting development server"
  task 'dev', ->
    spawn "supervisor", "-e js\|jade\|coffee -w routes,views,. app.coffee".split " "


# SPECS
runSpecs = (params, reporter, done) ->
  spawn "#{__dirname}/node_modules/mocha/bin/mocha", "
      --colors
      --timeout 2000
      --recursive
      --compilers coffee:coffee-script
      #{params || ''}
      --reporter #{reporter || 'dot'}
      specs
  ".trim().split(/\s+/), done

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
  basepath = __dirname + "/data/create"
  Importer = require './lib/importer'
  new Importer basepath