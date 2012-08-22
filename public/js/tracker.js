;(function(window, $, undefined) {

  // See: http://ralphvanderpauw.com/analytics/error-pages-google-analytics-update/

  var account = $('meta[property="ga:account"]').attr('content') || null
  var enabled = !!account; // If we have account info, assume we will use it.

  if (Modernizr.localstorage) {
    // Check if the user opted out of tracking.
    // Should only be used for development/testing purposes.
    if (localStorage.trackUser !== undefined)
      enabled = localStorage.trackUser
  }

  window._gaq = window._gaq || [];
  _gaq.push(['_setAccount', account]);
  _gaq.push(['_trackPageview']);

  if (enabled) {
    var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
    ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
    var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
  }

  function trackEvent(category, action, label, noninteraction) {
    // https://developers.google.com/analytics/devguides/collection/gajs/methods/gaJSApiEventTracking
    if (typeof _gaq != 'undefined') {
      var a = ['_trackEvent']
      a = a.concat([category, action, label, undefined, noninteraction])
      _gaq.push.call(_gaq, a)
    }
  }

  window.Track = {
    event: trackEvent
  }

})(this, jQuery);