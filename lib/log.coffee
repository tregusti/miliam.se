Path = require 'path'
winston = require 'winston'

consoleTransport = new winston.transports.Console
  colorize: true

path = if config.get('log:location').match /^\//
         config.get('log:location')
       else
         Path.join ROOT_DIR, config.get('log:location')

fileTransport = new winston.transports.File
  filename: path

module.exports = (prefix) ->
  throw new Error "No prefix specified for logger" unless prefix?

  transports = []
  transports.push consoleTransport if config.get 'log:console'
  transports.push fileTransport    if config.get 'log:file'

  logger = new winston.Logger
    transports: transports

  logger.log = ->
    arguments[1] = "#{prefix}: #{arguments[1]}" if prefix and arguments[1]
    winston.Logger.prototype.log.apply this, arguments

  logger