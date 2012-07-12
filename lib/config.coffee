nconf = require 'nconf'

nconf.defaults
  env: 'test'
  paths:
    create: '/tmp/data/create'
    data:   '/tmp/data'

nconf.file file: '../config.json'

nconf.use 'memory'

nconf.load()

module.exports = nconf