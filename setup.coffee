Path = require 'path'

# Set default time zone
process.env.TZ = 'Europe/Stockholm'

global.ROOT_DIR = Path.resolve __dirname
global.config = require './lib/config'