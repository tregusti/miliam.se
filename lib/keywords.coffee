fs = require 'fs'
log = require('./log') 'Keywords'

keywords = []

path = config.get('paths:data') + "/keywords.json"
try
  data = fs.readFileSync path, 'utf8'
  keywords = JSON.parse data
catch error
  log.error 'No keywords.json file available in data dir.'

module.exports = keywords