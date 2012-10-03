// Generated by CoffeeScript 1.3.3
(function() {

  if (!(window.mem0r1es != null)) {
    window.mem0r1es = {};
  }

  window.mem0r1es.NetworkListener = (function() {

    function NetworkListener() {
      chrome.webNavigation.onCompleted.addListener(this.onCompleted, {
        urls: ["*://*/*"]
      }, []);
    }

    NetworkListener.prototype.onBeforeRequestCallback = function(details) {
      console.log(details.url);
    };

    return NetworkListener;

  })();

}).call(this);
