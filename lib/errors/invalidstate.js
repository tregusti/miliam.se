var ErrorBase = require('./base');

function InvalidStateError(message) {
  this.message = message || "Object is in an invalid state";
};

InvalidStateError.prototype = Object.create(ErrorBase.prototype);
InvalidStateError.prototype.constructor = InvalidStateError;
InvalidStateError.prototype.name = 'InvalidStateError';


module.exports = InvalidStateError;