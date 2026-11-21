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

  // orbit rings around the lab logo (matches the Lovable hero)
  var oc = document.querySelector(".orbit-canvas");
  if (oc) {
    var octx = oc.getContext("2d"), ow = 0, oh = 0, orbStars = [];
    var RINGS = 6;
    function osize() {
      var dpr = Math.min(window.devicePixelRatio || 1, 2);
      ow = oc.clientWidth; oh = oc.clientHeight;
      oc.width = ow * dpr; oc.height = oh * dpr;
      octx.setTransform(dpr, 0, 0, dpr, 0, 0);
    }
    function ring(i) {
      var base = Math.min(ow * 0.46, 760);
      return { rx: base + i * Math.min(ow * 0.04, 62), ry: oh * 0.21 + i * oh * 0.032 };
    }
    var seeds = [[0, 4.4], [1, 0.3], [2, 2.6], [3, 5.6], [4, 1.5], [5, 3.6]];
    seeds.forEach(function (s, k) { orbStars.push({ ring: s[0], a: s[1], w: 0.018 + (k % 3) * 0.006 }); });
    var last = 0;
    function odraw(t) {
      var dt = last ? Math.min((t - last) / 1000, 0.1) : 0; last = t;
      octx.clearRect(0, 0, ow, oh);
      var cx = ow / 2, cy = oh / 2;
      octx.lineWidth = 1;
      for (var i = 0; i < RINGS; i++) {
        var r = ring(i);
        octx.strokeStyle = "rgba(225,232,245," + (0.42 - i * 0.04) + ")";
        octx.beginPath(); octx.ellipse(cx, cy, r.rx, r.ry, 0, 0, 6.2832); octx.stroke();
      }
      orbStars.forEach(function (s) {
        if (!reduce) s.a += s.w * dt;
        var r = ring(s.ring), x = cx + r.rx * Math.cos(s.a), y = cy + r.ry * Math.sin(s.a);
        var g = octx.createRadialGradient(x, y, 0, x, y, 9);
        g.addColorStop(0, "rgba(255,255,255,0.95)"); g.addColorStop(0.25, "rgba(235,242,255,0.55)"); g.addColorStop(1, "rgba(220,230,255,0)");
        octx.fillStyle = g; octx.beginPath(); octx.arc(x, y, 9, 0, 6.2832); octx.fill();
        octx.fillStyle = "#fff"; octx.beginPath(); octx.arc(x, y, 1.8, 0, 6.2832); octx.fill();
      });
      if (!reduce) requestAnimationFrame(odraw);
    }
    osize(); addEventListener("resize", osize); requestAnimationFrame(odraw);
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
