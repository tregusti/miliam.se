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

desc 'Run all specs'
task 'specs', ->
  cmd = child.spawn "./node_modules/mocha/bin/mocha", "--colors --timeout 1000 --recursive --compilers coffee:coffee-script specs".split ' '
  cmd.stdout.on 'data', (data) -> process.stdout.write data
  cmd.stderr.on 'data', (data) -> process.stderr.write data