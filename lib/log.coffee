Path = require 'path'
winston = require 'winston'
# eyes = require('eyes').inspector stream: null

LOG_LOCATION = Path.resolve Path.join __dirname, '..', '..', 'log'

console = new winston.transports.Console
  colorize: true

file = new winston.transports.File
  filename: Path.join(LOG_LOCATION, 'application.log')

log = new winston.Logger
  transports: [ console, file ]

module.exports = log