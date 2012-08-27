express = require 'express'

module.exports = (req, res) ->
  middleware = express.static config.get 'paths:data'
  middleware req, res
