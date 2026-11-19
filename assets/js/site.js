(function () {
  // mobile menu
  var btn = document.querySelector(".menu-btn");
  var list = document.getElementById("nav-list");
  if (btn && list) {
    btn.addEventListener("click", function () {
      var open = list.classList.toggle("open");
      btn.setAttribute("aria-expanded", open ? "true" : "false");
    });
    list.addEventListener("click", function (e) {
      if (e.target.closest("a")) { list.classList.remove("open"); btn.setAttribute("aria-expanded", "false"); }
    });
  }

  var reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  // reveal on scroll
  var els = document.querySelectorAll(".reveal");
  if ("IntersectionObserver" in window && !reduce) {
    var io = new IntersectionObserver(function (entries) {
      entries.forEach(function (en) { if (en.isIntersecting) { en.target.classList.add("in"); io.unobserve(en.target); } });
    }, { rootMargin: "0px 0px -8% 0px" });
    els.forEach(function (el) { io.observe(el); });
  } else {
    els.forEach(function (el) { el.classList.add("in"); });
  }

  // active nav item
  var links = document.querySelectorAll(".nav a.navlink[href^='#']");
  if (links.length && "IntersectionObserver" in window) {
    var map = {};
    links.forEach(function (a) { map[a.getAttribute("href").slice(1)] = a; });
    var so = new IntersectionObserver(function (entries) {
      entries.forEach(function (en) {
        if (en.isIntersecting && map[en.target.id]) {
          links.forEach(function (a) { a.removeAttribute("aria-current"); });
          map[en.target.id].setAttribute("aria-current", "true");
        }
      });
    }, { rootMargin: "-45% 0px -50% 0px" });
    Object.keys(map).forEach(function (id) { var s = document.getElementById(id); if (s) so.observe(s); });
  }

  // starfield
  var c = document.getElementById("stars");
  if (!c) return;
  var ctx = c.getContext("2d");
  var stars = [];
  function size() {
    var dpr = Math.min(window.devicePixelRatio || 1, 2);
    c.width = innerWidth * dpr; c.height = innerHeight * dpr;
    c.style.width = innerWidth + "px"; c.style.height = innerHeight + "px";
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    var n = Math.round((innerWidth * innerHeight) / 5200);
    stars = [];
    for (var i = 0; i < n; i++) {
      stars.push({ x: Math.random() * innerWidth, y: Math.random() * innerHeight, r: Math.random() < 0.94 ? Math.random() * 0.9 + 0.2 : Math.random() * 1.4 + 0.9, a: Math.random() * 0.7 + 0.15, p: Math.random() * 6.28, s: Math.random() * 0.02 + 0.004 });
    }
  }
  function draw(t) {
    ctx.clearRect(0, 0, innerWidth, innerHeight);
    for (var i = 0; i < stars.length; i++) {
      var s = stars[i];
      var a = reduce ? s.a : s.a * (0.65 + 0.35 * Math.sin(s.p + t * s.s * 0.06));
      ctx.globalAlpha = a;
      ctx.fillStyle = "#dbe6ff";
      ctx.beginPath(); ctx.arc(s.x, s.y, s.r, 0, 6.283); ctx.fill();
    }
    if (!reduce) requestAnimationFrame(draw);
  }
  size();
  addEventListener("resize", size);
  requestAnimationFrame(draw);
})();
