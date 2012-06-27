var ErrorBase = require('./base');

var ArgumentError = function(argname, message) {
  this.message = message || "Not a valid argument"
  this.argumentName = argname;
};

ArgumentError.prototype = Object.create(ErrorBase.prototype);
ArgumentError.prototype.constructor = ArgumentError;
ArgumentError.prototype.name = 'ArgumentError';


module.exports = ArgumentError;