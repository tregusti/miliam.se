var ErrorBase = function() {}
ErrorBase.prototype.toString = function() {
  return this.constructor.name + ": " + this.message;
};

ErrorBase.prototype = Object.create(Error.prototype);
ErrorBase.prototype.constructor = ErrorBase;
ErrorBase.prototype.name = 'ErrorBase';


module.exports = ErrorBase;