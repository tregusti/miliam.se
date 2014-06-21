require 'colors'
require './setup'

fs            = require 'fs'
CoffeeScript  = require 'coffee-script'
child         = require 'child_process'
Path          = require 'path'
Entry         = require './lib/entry'
EntryList     = require './lib/entry-list'
Importer      = require './lib/importer'

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
  cmd.on 'exit', done if done
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
runSpecs = (params, grep, reporter, done) ->
  params ||= ''
  grep = if grep then "--grep #{grep}" else ''
  env =
    NODE_ENV: 'test'
  args = "
      --colors
      --timeout 200
      --recursive
      --growl
      --compilers coffee:coffee-script
      --require coffee-script
      --require setup.coffee
      #{grep}
      #{params}
      --reporter #{reporter || 'dot'}
      specs
  ".trim()
  spawn "#{__dirname}/node_modules/mocha/bin/mocha", args.split(/\s+/), env, (code, signal) ->
    done code, signal if done
    fail code if code

desc 'Run all specs'
task 'specs', ->
  task = jake.Task['specs:compact']
  task.invoke.apply task, arguments

namespace 'specs', ->
  task 'compact', (grep) ->
    runSpecs null, grep

  desc 'Run all specs and pretty print'
  task 'pretty', (grep) ->
    runSpecs null, grep, 'spec'

  desc 'Run specs with debugger'
  task 'debug', (grep) ->
    console.log "Running specs and start node-inspector".blue
    runSpecs "--debug-brk", grep, null, ->
      console.log "\nSpecs done, kill inspector".blue
      insp.kill()
    insp = spawn 'node-inspector'

  desc 'Continously run specs watching for file changes'
  task 'watch', (grep) ->
    runSpecs "--watch", grep


# IMPORT
desc 'Import if needed'
task 'import', ->
  jake.Task['import:check'].invoke (err) ->
    return console.error err.message.red if err

    Entry.load config.get('paths:create'), (err, entry) ->
      return console.error err.message.red if err

      Importer.import entry, config.get('paths:data'), (err) ->
        return console.error err.message.red if err

        console.info "Import ok!".green

namespace 'import', ->
  desc 'Check if import state is ok'
  task 'check', (callback) ->
    Importer.check (err) ->
      if callback instanceof Function
        callback err
      else
      if err
          console.error "Error: #{err.message}".red
        else
          console.info 'OK!'.green

# EXPORT
namespace 'export', ->
  desc 'Export data to ghost json format'
  task 'json', (style) ->
    EntryList.load config.get('paths:data'), (err, data) ->
      return console.error err if err

      out =
        meta:
          exported_on: (new Date).getTime()
          version: '000'
        data:
          posts: []
          tags: [{
            id: 1,
            name: "Quote",
            slug: 'quote'
          }]
          posts_tags: []

      build = (entry) ->
        # Guards
        throw new Error 'bad time for entry.' unless entry.time

        id   = out.data.posts.length + 1
        date = entry.time.getTime()
        out.data.posts_tags.push { post_id: id, tag_id: 1 } if entry.type is 'quote'

        # Return object
        id:    id
        title: entry.title.trim() # trailing tab in some case
        slug:  entry.slug
        # TODO image:
        markdown: entry.text or ''
        page:     false
        statue:   'published',
        language: 'sv_SE'
        author_id: 1
        created_at: date,
        created_by: 1,
        published_at: date,
        published_by: 1

      out.data.posts.push build entry for entry in data.entries.reverse()
      json = if style is 'pretty' then JSON.stringify out, null, 2 else JSON.stringify out
      console.log json
