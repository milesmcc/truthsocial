// @ts-check

(function() {
  'use strict';

  /**
   * @param {() => void} loaded
   */
  var ready = function(loaded) {
    if (['interactive', 'complete'].indexOf(document.readyState) !== -1) {
      loaded();
    } else {
      document.addEventListener('DOMContentLoaded', loaded);
    }
  };

  ready(function() {
    /** @type {Map<number, HTMLIFrameElement>} */
    var iframes = new Map();

    window.addEventListener('message', function(e) {
      var data = e.data || {};

      if (typeof data !== 'object' || data.type !== 'setHeight' || !iframes.has(data.id)) {
        return;
      }

      var iframe = iframes.get(data.id);

      if ('source' in e && iframe.contentWindow !== e.source) {
        return;
      }

      var hasVideo = iframe.classList.contains('truthsocial-video');

      iframe.height = hasVideo ? data.height + 165 : data.height;
    });

    [].forEach.call(document.querySelectorAll('iframe.truthsocial-embed'), function(iframe) {
      // select unique id for each iframe
      var id = 0, failCount = 0, idBuffer = new Uint32Array(1);
      while (id === 0 || iframes.has(id)) {
        id = crypto.getRandomValues(idBuffer)[0];
        failCount++;
        if (failCount > 100) {
          // give up and assign (easily guessable) unique number if getRandomValues is broken or no luck
          id = -(iframes.size + 1);
          break;
        }
      }

      iframes.set(id, iframe);

      iframe.scrolling      = 'no';
      iframe.style.overflow = 'hidden';
      iframe.style.borderRadius = '8px';
      iframe.style.border = '1px solid rgb(237 237 239)';

      iframe.onload = function() {
        iframe.contentWindow.postMessage({
          type: 'setHeight',
          id: id,
        }, '*');
      };

      iframe.onload();
    });
  });
})();
