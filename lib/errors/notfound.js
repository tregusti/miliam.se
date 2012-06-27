var ErrorBase = require('./base');

var NotFoundError = function(path) {
  this.message = "'" + path + "' does not exist."
};

NotFoundError.prototype = Object.create(ErrorBase.prototype);
NotFoundError.prototype.constructor = NotFoundError;
NotFoundError.prototype.name = 'NotFoundError';


module.exports = ArgumentError;
