;(function(window, document, $, undefined) {

  var More = (function() {

    var currentPage,
        re = /^(.*?)(?:\/p([1-9]\d*)\/?)?/;

    function clickHandler() {
      disable();
      var m = document.location.pathname.match(re)
      if (m) {
        var path = m[1];
        currentPage = currentPage !== undefined ? currentPage : m[2] || 1
        $.get(path + '/p' + ++currentPage).done(function(html) {
          $('#more').before(html);
          html && enable(); // Enable if we got data back
        })
      }
    }

    function enable() {
      $('#more')
        .addClass('enabled')
        .on('click', clickHandler);
    }

    function disable() {
      $('#more')
        .removeClass('enabled')
        .off('click', clickHandler);
    }

    return {
      enable: enable
    }

  })();

  function scrollDown() {
    var nav = $('#navigation'),
        h = nav.outerHeight() - 20
    if (nav.length && document.body.scrollTop === 0) {
      setTimeout(function() {
        nav.show();
        window.scroll(0, h);
      }, 1)
    }
  }

  function update(subject) {
    var content = null;

    if (subject === 'windows') {
      content = 'Du har en mycket gammal version av Windows. Detta gör att du inte kan uppgradera din webbläsare, Internet Explorer. Detta gör att denna sida inte upplevs och ser ut så bra som den skulle kunna göra.<br><br>Utöver detta är du också utsatt för onödigt stora <a href="http://news.cnet.com/8301-1009_3-20063220-83.html" target="_blank">säkerhetsrisker</a>.<br><br>Du borde verkligen överväga att <a href="http://www.microsoft.com/windows">uppgradera</a>.';
    } else if (subject === 'ie') {
      content = 'Du har en gammal version av din webbläsare, Internet Explorer. För att uppleva många olika webbplatser, inklusive denna, mycket bättre och säkrare så borde du <a href="http://windows.microsoft.com/sv-SE/windows7/Update-Internet-Explorer" target="_blank">uppgradera</a> kostnadfritt.';
    }
    if (content) {
      Track.event('Update warning', subject, navigator.userAgent);
      var elm = $('<div id="update-warning">');
      elm.html(content);
      $(document.body).prepend(elm);
    }
  }

  $(function() {

    More.enable();

    if ($.browser.msie && $.browser.version <= 8) {

      var m = navigator.userAgent.match(/Windows NT (\d+)/);
      if (m && m[1] < 6) {
        // XP or less
        update('windows');
      } else {
        // just update ie
        update('ie');
      }
    } else {
      scrollDown()
    }
  })

})(window, document, jQuery)