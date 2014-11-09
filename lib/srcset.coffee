data2www = require './data2www'

module.exports = (image) ->
  """
  #{data2www(image.w320)} 320w,
  #{data2www(image.w640)} 640w,
  #{data2www(image.w1024)} 1024w
  """
