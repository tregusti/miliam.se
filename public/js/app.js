;(function(window, document, $, undefined) {

  $(function() {
    var nav = $('#navigation'),
        h = nav.outerHeight() - 20
    if (nav.length && document.body.scrollTop === 0) {
      setTimeout(function() {
        nav.show();
        window.scroll(0, h);
      }, 1)
    }
  })

})(window, document, jQuery)