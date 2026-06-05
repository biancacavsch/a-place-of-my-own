(function() {
  var link = document.createElement("link");
  link.rel = "stylesheet";
  link.href = "css/style.css?v=" + Math.floor(Date.now() / 3600000);
  document.head.appendChild(link);
})();