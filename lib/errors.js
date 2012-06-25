// function CustomError = function() {}
// CustomError.prototype = new Error();
// CustomError.prototype.toString = function toString() {
//   return this.name + ": " + this.message;
// }

var errors = {};

errors.NotFoundError = function (path) {
  Error.call(this, "'" + path + "' does not exist.");
}
errors.ArgumentError = function(arg, message) {
  message = message || "Not a valid argument"
  this.argumentName = arg;
  Error.call(this, "'" + arg + "': " + message);
}
errors.EntryError = function(path, message) {
  message = message || "Data for entry at '" + path + "' is invalid."
  Error.call(this, message);
}

for (var name in errors) {
  errors[name].prototype = new Error();
  errors[name].prototype.constructor = errors[name];
  errors[name].prototype.name = name;
  exports[name] = errors[name];
}