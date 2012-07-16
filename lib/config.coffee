module.exports = nconf = require 'nconf'
Path = require 'path'

env = if process.env.NODE_ENV and process.env.NODE_ENV.match /^(development|production|test)$/
        process.env.NODE_ENV
      else
        "test"

APPDIR = Path.resolve Path.join __dirname, '..'

nconf.use 'memory',
  loadFrom: [
    "#{APPDIR}/config/all.json",
    "#{APPDIR}/config/#{env}.json"
  ]

nconf.set 'env', env
process.env.NODE_ENV = env