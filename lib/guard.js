var ArgumentError = require('./errors/argument');

module.exports = {
  string: function(name, value) {
    if (!value || typeof(value) !== 'string')
      throw new ArgumentError("Argument '" + name + "' must be a non-empty string")
  },
  func: function(name, value) {
    if (!value || typeof(value) !== 'function')
      throw new ArgumentError("Argument '" + name + "' must be a function")
  }
}