// Expand hamburger menu when clicked
window.addEventListener("load", function(event) {
  var hamburgerList = document.querySelectorAll(".hamburger");
  hamburgerList.forEach(function(hamburger) {
    hamburger.onclick = function(){
      var navList = document.querySelectorAll(".sidebar-nav");
      navList.forEach(function(nav) {
        nav.classList.toggle('closed-when-mobile')
      });
    };
  })
});
