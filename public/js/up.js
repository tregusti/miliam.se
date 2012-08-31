;(function(window, $, undefined) {

  $(function() {
    $('#up').on('click', function(e) {
      window.scroll(0, 0);
      e.preventDefault();
    });
  });

  function scrollHandler(e) {
    opacity = window.scrollY > 100 ? 1 : 0;
    $('#up').css("opacity", opacity);
  }

  $(window).on('scroll', scrollHandler.throttle(50));

})(this, jQuery);