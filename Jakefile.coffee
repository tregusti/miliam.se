fs = require 'fs'
child = require 'child_process'
require 'colors'

invoke = (tasks) ->
  tasks.forEach (task) ->
    console.log "Invoking #{task.blue}:"
    jake.Task[task].invoke()


desc 'List all available tasks'
task 'default', ->
  console.log "This is the same as running 'jake -T'.\n"
  child.exec 'jake -T', (error, stdout, stderr) ->
    console.log stdout

runSpecs = (params, reporter) ->
  cmd = child.spawn "./node_modules/mocha/bin/mocha", "
      --colors
      --timeout 1000
      --recursive
      --compilers coffee:coffee-script
      #{params || ''}
      --reporter #{reporter || 'dot'}
      specs
  ".trim().split /\s+/
  cmd.stdout.on 'data', (data) -> process.stdout.write data
  cmd.stderr.on 'data', (data) -> process.stderr.write data


desc 'Run all specs'
task 'specs', (params) ->
  runSpecs()

namespace 'specs', ->
  desc 'Run all specs and pretty print'
  task 'pretty', -> runSpecs null, 'spec'

  desc 'Continously run specs watching for file changes'
  task 'watch', -> runSpecs "--watch --growl"