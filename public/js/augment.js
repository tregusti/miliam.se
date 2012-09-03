Function.prototype.debounce = function (threshold, execAsap) {
  var func = this, // reference to original function
      timeout; // handle to setTimeout async task (detection period)
  // return the new debounced function which executes the original function only once
  // until the detection period expires
  return function debounced() {
    var obj = this,
      // reference to original context object
      args = arguments; // arguments at execution time
    // this is the detection function. it will be executed if/when the threshold expires
    function delayed() {
      // if we're executing at the end of the detection period
      if (!execAsap) func.apply(obj, args); // execute now
      // clear timeout handle
      timeout = null;
    };
    // stop any current detection period
    if (timeout) clearTimeout(timeout);
    // otherwise, if we're not already waiting and we're executing at the beginning of the detection period
    else if (execAsap) func.apply(obj, args); // execute now
    // reset the detection period
    timeout = setTimeout(delayed, threshold || 100);
  };
};

Function.prototype.curry = function curry() {
  var fn = this,
    args = Array.prototype.slice.call(arguments);
  return function curried() {
    return fn.apply(this, args.concat(Array.prototype.slice.call(arguments)));
  };
};


Function.prototype.throttle = function(t) {
  var timeout, scope, args, fn = this, tick = function() {
    fn.apply(scope, args)
    timeout = null
  }
  return function() {
    scope = this
    args = arguments
    if (!timeout) timeout = setTimeout(tick, t)
  }
}