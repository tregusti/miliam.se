;(function(window, $, undefined) {

  var more,
      currentPage,
      re = /^(.*?)(?:\/p([1-9]\d*)\/?)?$/;

  function clickHandler() {
    disable();
    var m = document.location.pathname.match(re)
    if (m) {
      // trim away trainling / if any
      var path = m[1].replace(/\/$/, '');
      currentPage = currentPage !== undefined ? currentPage : m[2] || 1
      $.getJSON(path + '/p' + ++currentPage).done(function(json) {
        more.before(json.html);
        if (json.more)
          enable(); // Enable if there's more to fetch
        else
        more.remove()
      })
    }
  }

  function enable() {
    if (!more)
      more = $('#more');

    more
      .addClass('enabled')
      .on('click', clickHandler);
  }

  function disable() {
    more
      .removeClass('enabled')
      .off('click', clickHandler);
  }

  window.More = {
    enable: enable
  };

})(this, jQuery);