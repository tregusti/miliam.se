Path = require 'path'
winston = require 'winston'
config = require './config'

consoleTransport = new winston.transports.Console
  colorize: true

fileTransport = new winston.transports.File
  filename: config.get 'paths:log'

module.exports = (prefix) ->
  throw new Error "No prefix specified for logger" unless prefix?

  logger = new winston.Logger
    transports: [ consoleTransport, fileTransport ]

  logger.log = ->
    arguments[1] = "#{prefix}: #{arguments[1]}" if prefix and arguments[1]
    winston.Logger.prototype.log.apply this, arguments

  logger