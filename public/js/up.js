;(function(window, $, undefined) {

  $(function() {
    $('#up').on('click', function(e) {
      window.scroll(0, 0);
      e.preventDefault();
    });
  });

})(this, jQuery);