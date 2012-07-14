Path = require 'path'
winston = require 'winston'
config = require './config'

# eyes = require('eyes').inspector stream: null

LOG_LOCATION = config.get 'paths:log'

consoleTransport = new winston.transports.Console
  colorize: true

fileTransport = new winston.transports.File
  filename: Path.join(LOG_LOCATION, 'application.log')

module.exports = (prefix) ->
  throw new Error "No prefix specified for logger" unless prefix?

  logger = new winston.Logger
    transports: [ consoleTransport, fileTransport ]

  logger.log = ->
    arguments[1] = "#{prefix}: #{arguments[1]}" if prefix and arguments[1]
    winston.Logger.prototype.log.apply this, arguments

  logger