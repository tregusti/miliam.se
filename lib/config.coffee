nconf = require 'nconf'
Path = require 'path'

nconf.use 'memory'

nconf.defaults
  env: 'test'
  port: 4000
  paths:
    create: '/tmp/data/create'
    data:   '/tmp/data'
    log:    Path.join(__dirname, '..', '..', 'log')

nconf.file file: '../config.json'

# Port
nconf.set 'port', process.env.PORT || nconf.get 'port'

# Environment
env = if process.env.NODE_ENV and process.env.NODE_ENV.match /^(development|production|test)$/
        process.env.NODE_ENV
      else
        nconf.get 'env'
nconf.set 'env', env
process.env.NODE_ENV = env

module.exports = nconf