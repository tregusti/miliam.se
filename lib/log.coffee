Path = require 'path'
winston = require 'winston'

LOG_LOCATION = Path.resolve Path.join __dirname, '..', '..', 'log'

log = new winston.Logger
  transports: [
    new winston.transports.Console colorize: true,
    new winston.transports.File filename: Path.join(LOG_LOCATION, 'application.log')
  ]

module.exports = log