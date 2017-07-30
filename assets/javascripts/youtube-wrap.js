// Mobile Friendly Youtube Embed via JavaScript: https://codepen.io/schneems/pen/woreoR
//
window.addEventListener("load", function(event) {
  var elementList = document.querySelectorAll("iframe");
  elementList.forEach(function(elem) {

    // Only apply to Youtube players
    var src = elem.getAttribute('src');
    if (src && src.indexOf('youtube') !== -1) {
      var div = document.createElement('div');
      div.innerHTML = elem.outerHTML;
      div.setAttribute('class', 'video-container');

      elem.parentNode.insertBefore(div, elem);
      elem.remove();
    }

  });
});
