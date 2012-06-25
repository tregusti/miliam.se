// function CustomError = function() {}
// CustomError.prototype = new Error();
// CustomError.prototype.toString = function toString() {
//   return this.name + ": " + this.message;
// }

function NotFoundError(path) {
  Error.call(this, "'" + path + "' does not exist.");
}

NotFoundError.prototype = new Error();
NotFoundError.prototype.constructor = NotFoundError;
NotFoundError.prototype.name = 'NotFoundError';



function ArgumentError(arg, message) {
  message = message || "Not a valid argument"
  this.argumentName = arg;
  Error.call(this, "'" + arg + "': " + message);
}

ArgumentError.prototype = new Error();
ArgumentError.prototype.constructor = ArgumentError;
ArgumentError.prototype.name = 'ArgumentError';

exports.NotFoundError = NotFoundError;
exports.ArgumentError = ArgumentError;