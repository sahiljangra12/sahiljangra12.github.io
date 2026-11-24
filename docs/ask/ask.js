/* Ask: the search box on Sahil's sites.

   One file, no libraries, no account and no key. It reads the pages of the site it is on, inside the visitor's browser,
   and answers a question with the passage that fits best and a link to it. That part is free and has no limit.
   When the Data AI service has allowance left for the day, the same passages are sent to it and its short answer
   replaces the passage; when it has none, or cannot be reached, the visitor still gets the built-in answer.

   Use:  <script defer src="https://sahiljangra12.github.io/ask/ask.js" data-site="Site name"></script>
   Optional attributes: data-base="/folder/" (which pages belong to the site), data-pages="a.html,b.html" (extra pages
   to read), data-about="One sentence about the site", data-accent="#2f6df6", data-side="left", data-lang="hi". */
(function () {
  "use strict";
  if (window.__askLoaded || window.top !== window.self && !document.currentScript.dataset.frame) return;
  window.__askLoaded = true;
  var S = document.currentScript, D = S.dataset, AI_URL = D.ai === "off" ? "" : (D.ai || "https://open-data-ai.netlify.app/api/data-ai");
  var seg = location.pathname.split("/")[1] || "";
  var BASE = D.base || (/\.github\.io$/.test(location.hostname) && seg && !/\.html?$/.test(seg) && D.root !== "1" ? "/" + seg + "/" : "/");
  var SITE = D.site || document.title.split(/[|·—–-]/)[0].trim() || "this site";
  var ABOUT = D.about || ((document.querySelector('meta[name="description"]') || {}).content || "");
  var HI = (D.lang || document.documentElement.lang || "en").slice(0, 2) === "hi";
  var T = HI ? { ask: "पूछें", title: "इस साइट में खोजें", ph: "अपना सवाल लिखें…", send: "भेजें", close: "बंद करें", reading: "साइट पढ़ी जा रही है…",
      hello: "नमस्ते! इस साइट के बारे में कुछ भी पूछें।", none: "इस साइट पर इसका जवाब नहीं मिला। ये आज़माएँ:", open: "यह हिस्सा खोलें", more: "और देखें", ai: "AI उत्तर", aiNote: "AI ने नीचे दिए हिस्सों से लिखा है। गलती हो सकती है, स्रोत देखें।", here: "इसी पेज पर", try_: "उदाहरण", foot: "जवाब इसी साइट के पन्नों से।" }
    : { ask: "Ask", title: "Ask " + SITE, ph: "Type a question…", send: "Send", close: "Close", reading: "Reading the site…",
      hello: "Hi! Ask me anything about " + SITE + ".", none: "I could not find that on this site. You could try:", open: "Open this part", more: "Also on this site", ai: "AI answer", aiNote: "Written by AI from the parts below. It can be wrong, so check the source.", here: "on this page", try_: "Try", foot: "Answers come from this site's own pages." };

  /* ---------- words ---------- */
  var STOP = {}; ("a an and are as at be but by can could did do does for from had has have how i if in into is it its me my of on or our so than that the their them then there these they this to was we were what when where which who whom why will with would you your about tell show give find please any some much many more most kya hai ka ki ke ko se me mein aur").split(" ").forEach(function (w) { STOP[w] = 1; });
  var SYN = { cost: ["price", "fee"], price: ["cost", "rate"], contact: ["email", "phone"], author: ["sahil", "made"], made: ["built", "author"], method: ["methods", "approach"], data: ["dataset", "source"], source: ["data"], download: ["csv", "pdf"], paper: ["report", "pdf"], report: ["paper"], result: ["finding"], finding: ["result"], weather: ["forecast", "rain"], bill: ["charge"], map: ["location"], food: ["dining", "eat", "restaurant"], eat: ["food", "dining", "meal"], hungry: ["food", "dining"], bus: ["shuttle"], mandi: ["price", "rate"] };
  function stem(w) { if (w.length > 4) { w = w.replace(/(ies)$/, "y").replace(/(sses)$/, "ss").replace(/([^s])s$/, "$1"); if (w.length > 5) w = w.replace(/(ing|ed)$/, ""); } return w; }
  function words(s) { var m = String(s).toLowerCase().match(/[\p{L}\p{N}\p{M}]+/gu) || [], out = []; for (var i = 0; i < m.length; i++) if (!STOP[m[i]] && (m[i].length > 1 || /\d/.test(m[i]))) out.push(stem(m[i])); return out; }
  function near(a, b) {                                         // true when two words differ by one edit (two for long words)
    var la = a.length, lb = b.length, max = la > 7 ? 2 : 1; if (Math.abs(la - lb) > max) return false;
    var prev = [], cur = [], i, j; for (j = 0; j <= lb; j++) prev[j] = j;
    for (i = 1; i <= la; i++) { cur = [i]; var low = i; for (j = 1; j <= lb; j++) { cur[j] = Math.min(prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + (a[i - 1] === b[j - 1] ? 0 : 1)); if (cur[j] < low) low = cur[j]; } if (low > max) return false; prev = cur; }
    return prev[lb] <= max;
  }

  /* ---------- reading pages into passages ---------- */
  var SKIP = "script,style,noscript,template,svg,canvas,nav,footer,select,option,textarea,iframe,object,[aria-hidden=true],[role=alert],[role=status],.ask-root,.sr-only,.visually-hidden";
  var INLINE = { A: 1, SPAN: 1, B: 1, I: 1, EM: 1, STRONG: 1, SUB: 1, SUP: 1, CODE: 1, SMALL: 1, ABBR: 1, MARK: 1, U: 1, S: 1, KBD: 1, VAR: 1, CITE: 1, Q: 1, TIME: 1, FONT: 1, BDI: 1, DATA: 1, OUTPUT: 1 };
  function passages(doc, url, live) {
    var title = (doc.title || "").split(/\s[|·—–]\s/)[0].trim() || SITE, out = [], head = title, anchor = "", el0 = null, buf = "", last = null;
    function flush() {                                           // sentences with a number the page fills in later are left out
      var x = buf.replace(/\s+/g, " ").trim(); buf = ""; if (x.indexOf("\u0001") >= 0) x = sentences(x).filter(function (s) { return s.indexOf("\u0001") < 0; }).join(" ");
      if (x.length > 40) out.push({ p: title, h: head, u: url + (anchor ? "#" + anchor : ""), x: x.slice(0, 1200), el: live ? el0 : null });
    }
    var desc = (doc.querySelector('meta[name="description"]') || {}).content; if (desc) out.push({ p: title, h: title, u: url, x: desc, el: null, lead: 1 });
    if (!doc.body) return out;
    var tw = doc.createTreeWalker(doc.body, 5, { acceptNode: function (n) { return n.nodeType === 1 && (n.matches(SKIP) || n.tagName === "LABEL" || n.tagName === "BUTTON" && n.textContent.length < 30) ? 2 : 1; } }), n;
    while ((n = tw.nextNode()) && out.length < 900) {
      if (n.nodeType === 1) {
        if (/^H[1-4]$/.test(n.tagName) || n.getAttribute("role") === "heading") {
          var parts = [], hw = doc.createTreeWalker(n, 4), t; while ((t = hw.nextNode())) if (t.nodeValue.trim()) parts.push(t.nodeValue.trim());
          var ht = parts.join(" ").replace(/\s+/g, " ").replace(/ ([.,;:?!])/g, "$1"); tw.currentNode = n; var nx = tw.nextSibling(); if (nx) tw.previousNode(); else { tw.currentNode = n; while (tw.lastChild()) {} }
          if (ht.length > 1) { flush(); head = ht.slice(0, 90); var holder = n.id ? n : n.closest("[id]"); anchor = holder && holder !== doc.body ? holder.id : ""; el0 = n; last = null; }
        } else if (n.tagName === "BR") buf += " ";
        else if (!live && !n.firstChild && (n.id || n.attributes.length > 1 || n.className) && INLINE[n.tagName]) buf += "\u0001";
        continue;
      }
      var v = n.nodeValue; if (!v.trim()) { if (v) buf += " "; continue; }
      var blk = n.parentNode; while (blk && INLINE[blk.tagName]) blk = blk.parentNode;
      if (blk !== last) { var e = buf.trim(); if (e && !/[.!?।:,;]$/.test(e)) buf = e + "."; if (buf.length + v.length > 900) flush(); buf += " "; last = blk; }
      buf += v;
    }
    flush(); return out;
  }
  var store = { get: function (k) { try { return JSON.parse(sessionStorage.getItem(k)); } catch (e) { return null; } }, set: function (k, v) { try { sessionStorage.setItem(k, JSON.stringify(v)); } catch (e) {} } };
  function inSite(u) { return u.origin === location.origin && u.pathname.indexOf(BASE) === 0 && /(\/|\.html?)$/.test(u.pathname) && !/\/(embed-|404)/.test(u.pathname) && !/\.pdf$/i.test(u.pathname); }
  function key(u) { return u.pathname.replace(/index\.html?$/, ""); }
  var other = null;
  function readSite() {                                          // the other pages of the site, fetched once for each visit
    if (other) return other;
    var k = "ask:" + BASE + ":3", saved = store.get(k); if (saved) return (other = Promise.resolve(saved));
    var here = key(location), list = {}, add = function (h) { try { var u = new URL(h, location.href); if (inSite(u) && key(u) !== here) list[key(u)] = u.origin + key(u); } catch (e) {} };
    add(BASE); (D.pages || "").split(",").forEach(function (p) { if (p.trim()) add(new URL(p.trim(), location.origin + BASE).href); });
    var a = document.querySelectorAll("a[href]"); for (var i = 0; i < a.length; i++) add(a[i].getAttribute("href"));
    var urls = Object.keys(list).slice(0, 40).map(function (x) { return list[x]; }), all = [];
    var one = function (u) { return fetch(u, { credentials: "omit" }).then(function (r) { return r.ok && /html/.test(r.headers.get("content-type") || "") ? r.text() : ""; }).then(function (h) {
      if (!h || h.length > 1500000) return; var ps = passages(new DOMParser().parseFromString(h, "text/html"), u, false); for (var i = 0; i < ps.length && i < 120; i++) all.push(ps[i]); }).catch(function () {}); };
    var q = urls.slice(), run = function () { var u = q.shift(); return u ? one(u).then(run) : null; };
    other = Promise.race([Promise.all([run(), run(), run(), run()]), new Promise(function (r) { setTimeout(r, 7000); })]).then(function () { if (all.length) store.set(k, all.slice(0, 1500)); return all; });
    return other;
  }

  /* ---------- ranking (BM25, with the heading counted three times) ---------- */
  function search(q, docs) {
    var qs = words(q); if (!qs.length) return { hits: [], qs: qs };
    var N = docs.length, df = {}, i, j, total = 0;
    for (i = 0; i < N; i++) { var d = docs[i]; if (!d.w) { var hw = words(d.h + " " + d.p); d.w = words(d.x).concat(hw, hw, hw); d.tf = {}; for (j = 0; j < d.w.length; j++) d.tf[d.w[j]] = (d.tf[d.w[j]] || 0) + 1; } total += d.w.length; for (var t in d.tf) df[t] = (df[t] || 0) + 1; }
    var avg = total / (N || 1), terms = [];
    qs.forEach(function (w) {
      if (df[w]) terms.push([w, 1]);
      else { var best = null; if (w.length > 4) for (var v in df) if (v[0] === w[0] && near(w, v) && (!best || df[v] > df[best])) best = v; if (best) terms.push([best, 0.8]); }
      (SYN[w] || []).forEach(function (s) { s = stem(s); if (df[s]) terms.push([s, 0.35]); });
    });
    var hits = [];
    for (i = 0; i < N; i++) { var dd = docs[i], sc = 0, got = 0; for (j = 0; j < terms.length; j++) { var f = dd.tf[terms[j][0]]; if (!f) continue; if (terms[j][1] >= 0.8) got++; var idf = Math.log(1 + (N - df[terms[j][0]] + 0.5) / (df[terms[j][0]] + 0.5)); sc += terms[j][1] * idf * f * 2.2 / (f + 1.2 * (0.25 + 0.75 * dd.w.length / avg)); }
      if (sc > 0) hits.push({ d: dd, s: sc * (0.6 + 0.4 * got / qs.length) * (dd.lead ? 1.1 : 1), got: got }); }
    hits.sort(function (a, b) { return b.s - a.s; });
    return { hits: hits, qs: qs, terms: terms.map(function (t) { return t[0]; }) };
  }
  function sentences(x) { var out = [], re = /[^.!?।]+(?:[.!?।]+(?=\s|$)|[.!?।](?=\S)[^.!?।\s]*|$)/g, m, cur = ""; while ((m = re.exec(x))) { cur += m[0]; if (/[.!?।]\s*$/.test(cur) && cur.trim().length > 25) { out.push(cur.trim()); cur = ""; } } if (cur.trim()) out.push(cur.trim()); return out; }
  function excerpt(d, terms) {                                    // the sentences of a passage that carry the question's words
    var ss = sentences(d.x); if (ss.length < 2) return d.x.slice(0, 340);
    var best = 0, bi = 0; ss.forEach(function (s, i) { var w = words(s), n = 0; terms.forEach(function (t) { if (w.indexOf(t) >= 0) n++; }); n = n + (i === 0 ? 0.1 : 0); if (n > best) { best = n; bi = i; } });
    var out = ss[bi], k = bi + 1; while (k < ss.length && (out + " " + ss[k]).length < 330) out += " " + ss[k++];
    k = bi - 1; while (k >= 0 && (ss[k] + " " + out).length < 330) out = ss[k--] + " " + out;
    return out.length > 420 ? out.slice(0, 400).replace(/\s\S*$/, "") + "…" : out;
  }

  /* ---------- the box ---------- */
  var css = ".ask-root{--ask:" + (D.accent || "#2f6df6") + ";--bg:#fff;--fg:#14171c;--mut:#5b6472;--line:#dfe3ea;--soft:#f2f4f8;font:15px/1.5 system-ui,-apple-system,'Segoe UI',Roboto,'Noto Sans Devanagari',sans-serif;color:var(--fg);text-align:left;letter-spacing:0}" +
    ".ask-root.ask-dark{--bg:#15181d;--fg:#eef1f5;--mut:#a3adba;--line:#2c323b;--soft:#1f242b}.ask-root *{box-sizing:border-box;font-family:inherit}" +
    ".ask-fab{position:fixed;z-index:2147483000;bottom:16px;right:16px;height:52px;min-width:52px;padding:0 18px 0 14px;border-radius:26px;border:0;background:var(--ask);color:#fff;font-size:15px;font-weight:600;display:inline-flex;align-items:center;gap:8px;cursor:pointer;box-shadow:0 6px 20px rgba(0,0,0,.28)}" +
    ".ask-left .ask-fab{right:auto;left:16px}.ask-fab svg{width:20px;height:20px;flex:none}.ask-fab:focus-visible,.ask-root button:focus-visible,.ask-root a:focus-visible{outline:3px solid var(--fg);outline-offset:2px}" +
    ".ask-panel{position:fixed;z-index:2147483001;right:16px;bottom:16px;width:400px;max-width:calc(100vw - 32px);height:560px;max-height:calc(100vh - 32px);max-height:calc(100dvh - 32px);background:var(--bg);border:1px solid var(--line);border-radius:16px;box-shadow:0 18px 60px rgba(0,0,0,.35);display:none;flex-direction:column;overflow:hidden}" +
    ".ask-left .ask-panel{right:auto;left:16px}.ask-open .ask-panel{display:flex}.ask-open .ask-fab{display:none}" +
    ".ask-top{display:flex;align-items:center;gap:8px;padding:6px 6px 6px 16px;border-bottom:1px solid var(--line)}.ask-top b{flex:1;font-size:15px;font-weight:650;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}" +
    ".ask-x{width:44px;height:44px;border:0;background:none;color:var(--fg);font-size:24px;line-height:1;border-radius:10px;cursor:pointer}" +
    ".ask-log{flex:1;overflow-y:auto;padding:14px 14px 4px;overscroll-behavior:contain;-webkit-overflow-scrolling:touch}" +
    ".ask-q{margin:0 0 10px auto;width:fit-content;max-width:86%;background:var(--ask);color:#fff;padding:9px 13px;border-radius:14px 14px 4px 14px;overflow-wrap:anywhere}" +
    ".ask-a{margin:0 0 14px;max-width:94%;background:var(--soft);padding:11px 13px;border-radius:14px 14px 14px 4px;overflow-wrap:anywhere}.ask-a h5{margin:0 0 4px;font-size:13px;font-weight:650;color:var(--mut);text-transform:none}" +
    ".ask-a p{margin:0 0 6px;font-size:15px;color:var(--fg)}.ask-a .ask-tag{display:inline-block;font-size:12px;font-weight:650;color:var(--ask);margin-bottom:4px}.ask-dark .ask-a .ask-tag{color:#9dbcff}" +
    ".ask-a a,.ask-chip{display:flex;align-items:center;min-height:44px;padding:6px 12px;margin-top:6px;border:1px solid var(--line);border-radius:10px;background:var(--bg);color:var(--fg);text-decoration:none;font-size:14px;line-height:1.3;cursor:pointer;text-align:left;width:100%}" +
    ".ask-a a span{color:var(--mut);font-size:12px;display:block}.ask-a a>div{flex:1;min-width:0}.ask-a a:after{content:'›';font-size:20px;color:var(--mut);margin-left:8px}.ask-a small{display:block;margin-top:8px;color:var(--mut);font-size:12px}" +
    ".ask-form{display:flex;gap:8px;padding:10px;border-top:1px solid var(--line)}.ask-in{flex:1;min-width:0;height:46px;border:1px solid var(--line);border-radius:12px;padding:0 12px;font-size:16px;background:var(--bg);color:var(--fg)}" +
    ".ask-in:focus{outline:2px solid var(--ask);outline-offset:0}.ask-go{height:46px;min-width:64px;padding:0 14px;border:0;border-radius:12px;background:var(--ask);color:#fff;font-size:15px;font-weight:600;cursor:pointer}" +
    ".ask-foot{padding:0 12px 8px;font-size:12px;color:var(--mut);text-align:center}.ask-dots:after{content:'…';animation:askd 1s steps(3) infinite}@keyframes askd{0%{opacity:.2}50%{opacity:1}}" +
    "@media(max-width:560px){.ask-panel{left:0!important;right:0!important;bottom:0;width:auto;max-width:none;height:82vh;height:82dvh;max-height:none;border-radius:18px 18px 0 0;border-width:1px 0 0}.ask-fab{padding:0 16px 0 13px}}" +
    "@media print{.ask-root{display:none}}@media(prefers-reduced-motion:reduce){.ask-dots:after{animation:none}}";
  var root, log, input, fab, busy = false;
  function h(tag, cls, text) { var e = document.createElement(tag); if (cls) e.className = cls; if (text != null) e.textContent = text; return e; }
  function dark() { var e = document.body, c; for (var i = 0; i < 2 && e; i++, e = document.documentElement) { c = getComputedStyle(e).backgroundColor.match(/[\d.]+/g); if (c && (c.length < 4 || +c[3] > 0.5)) return (0.299 * c[0] + 0.587 * c[1] + 0.114 * c[2]) < 110; } return matchMedia("(prefers-color-scheme: dark)").matches && D.theme === "auto"; }
  function lift() {                                               // stay clear of a tab bar or another floating button already in that corner
    if (!fab || root.classList.contains("ask-open")) return; fab.style.bottom = (+D.bottom || 16) + "px";
    for (var n = 0; n < 3; n++) { var r = fab.getBoundingClientRect(), top = null; fab.style.visibility = "hidden";
      [[r.left + 6, r.top + 6], [r.right - 6, r.bottom - 6], [(r.left + r.right) / 2, (r.top + r.bottom) / 2]].forEach(function (p) { var els = document.elementsFromPoint(p[0], p[1]);
        for (var i = 0; i < els.length; i++) { var e = els[i]; while (e && e !== document.body && e !== document.documentElement) { var ps = getComputedStyle(e).position; if (ps === "fixed" || ps === "sticky") { var b = e.getBoundingClientRect(); if (b.height < innerHeight * 0.5 && b.top > innerHeight * 0.4 && (top === null || b.top < top)) top = b.top; break; } e = e.parentElement; } } });
      fab.style.visibility = ""; if (top === null) break; fab.style.bottom = Math.round(innerHeight - top + 10) + "px"; }
  }
  function build() {
    var st = h("style"); st.textContent = css; document.head.appendChild(st);
    root = h("div", "ask-root" + (D.side === "left" ? " ask-left" : "")); root.setAttribute("lang", HI ? "hi" : "en");
    fab = h("button", "ask-fab"); fab.type = "button"; fab.setAttribute("aria-label", T.title); fab.setAttribute("aria-haspopup", "dialog");
    fab.innerHTML = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" aria-hidden="true"><circle cx="11" cy="11" r="7"/><path d="M20 20l-3.6-3.6"/></svg>'; fab.appendChild(h("span", "", T.ask));
    var panel = h("div", "ask-panel"); panel.setAttribute("role", "dialog"); panel.setAttribute("aria-label", T.title);
    var top = h("div", "ask-top"); top.appendChild(h("b", "", T.title)); var x = h("button", "ask-x", "×"); x.type = "button"; x.setAttribute("aria-label", T.close); top.appendChild(x);
    log = h("div", "ask-log"); log.setAttribute("aria-live", "polite");
    var form = h("form", "ask-form"); input = h("input", "ask-in"); input.type = "search"; input.placeholder = T.ph; input.maxLength = 300; input.setAttribute("aria-label", T.ph); input.autocomplete = "off"; input.enterKeyHint = "search";
    var go = h("button", "ask-go", T.send); go.type = "submit"; form.appendChild(input); form.appendChild(go);
    panel.appendChild(top); panel.appendChild(log); panel.appendChild(form); panel.appendChild(h("div", "ask-foot", T.foot));
    root.appendChild(fab); root.appendChild(panel); document.body.appendChild(root);
    fab.addEventListener("click", open); x.addEventListener("click", close);
    form.addEventListener("submit", function (e) { e.preventDefault(); var q = input.value.trim(); if (q && !busy) { input.value = ""; ask(q); } });
    root.addEventListener("keydown", function (e) { if (e.key === "Escape") { e.stopPropagation(); close(); } });
    addEventListener("resize", lift); setTimeout(lift, 1200); setTimeout(lift, 4000);
  }
  var greeted = false;
  function open() {
    root.classList.toggle("ask-dark", D.theme === "dark" || (D.theme !== "light" && dark())); root.classList.add("ask-open"); readSite(); checkAI();
    if (!greeted) { greeted = true; var a = h("div", "ask-a"); a.appendChild(h("p", "", T.hello)); if (ABOUT) a.appendChild(h("p", "", ABOUT.slice(0, 220)));
      var heads = [], seen = {}; passages(document, key(location), true).forEach(function (p) { if (!seen[p.h] && p.h !== p.p && p.h.length > 5 && p.h.length < 46 && heads.length < 3) { seen[p.h] = 1; heads.push(p.h); } });
      (D.try ? D.try.split("|") : heads).forEach(function (t) { var c = h("button", "ask-chip", t); c.type = "button"; c.addEventListener("click", function () { if (!busy) ask(t); }); a.appendChild(c); }); log.appendChild(a); }
    if (matchMedia("(min-width:561px)").matches) input.focus();
  }
  function close() { root.classList.remove("ask-open"); lift(); fab.focus(); }
  function link(d, sub, label) { var a = h("a"), box = h("div"); a.href = d.u; if (window.top !== window.self) a.target = "_top"; box.appendChild(document.createTextNode(label || d.h)); box.appendChild(h("span", "", sub || (d.el ? T.here : d.p))); a.appendChild(box);
    a.addEventListener("click", function (e) { if (d.el && d.el.isConnected && d.el.getClientRects().length) { e.preventDefault(); close(); d.el.scrollIntoView({ behavior: "smooth", block: "start" }); } else if (matchMedia("(max-width:560px)").matches) close(); }); return a; }

  /* ---------- the AI service: used when it says it is open, never needed ---------- */
  var ai = null;
  function checkAI() { if (ai !== null || !AI_URL) return; ai = false; var c = store.get("ask:ai"); if (c && Date.now() - c.at < 300000) { ai = c.on; return; }
    fetch(AI_URL).then(function (r) { return r.json(); }).then(function (j) { ai = !!(j && j.ai && j.site_search); store.set("ask:ai", { on: ai, at: Date.now() }); }).catch(function () {}); }
  function askAI(q, hits) {
    var ctl = new AbortController(), timer = setTimeout(function () { ctl.abort(); }, 20000);
    return fetch(AI_URL, { method: "POST", headers: { "content-type": "application/json" }, signal: ctl.signal, body: JSON.stringify({ mode: "site", site: SITE, about: ABOUT.slice(0, 300), question: q, lang: HI ? "hi" : "en",
      passages: hits.slice(0, 4).map(function (x) { return { title: x.d.h + " (" + x.d.p + ")", text: x.d.x.slice(0, 800) }; }) }) })
      .then(function (r) { return r.json(); }).then(function (j) { clearTimeout(timer); if (!j || !j.ok) { if (j && j.reason === "budget") { ai = false; store.set("ask:ai", { on: false, at: Date.now() }); } return ""; } return String(j.text || "").trim(); }).catch(function () { clearTimeout(timer); return ""; });
  }
  function paragraphs(box, text) { text.split(/\n{2,}|\n(?=- )/).forEach(function (para) { var p = h("p"); para.replace(/^- /, "• ").split(/\*\*(.+?)\*\*/).forEach(function (bit, i) { p.appendChild(i % 2 ? h("b", "", bit) : document.createTextNode(bit)); }); box.appendChild(p); }); }

  function ask(q) {
    busy = true; log.appendChild(h("div", "ask-q", q)); var a = h("div", "ask-a"), wait = h("p", "ask-dots", T.reading.replace("…", "")); a.appendChild(wait); log.appendChild(a); log.scrollTop = log.scrollHeight;
    var done = function () { busy = false; a.previousSibling.scrollIntoView({ block: "start" }); };
    if (/^(hi+|hello|hey|namaste|नमस्ते|thanks?|thank you|ok(ay)?)[\s!.]*$/i.test(q)) { a.textContent = ""; a.appendChild(h("p", "", /thank|ok/i.test(q) ? (HI ? "धन्यवाद!" : "You're welcome.") : T.hello)); return done(); }
    readSite().then(function (rest) {
      var docs = passages(document, key(location), true).concat(rest || []), r = search(q, docs), hits = [], seen = {};
      r.hits.forEach(function (x) { var k2 = x.d.h.toLowerCase(); if (!seen[k2] && hits.length < 4) { seen[k2] = 1; hits.push(x); } });
      var strong = hits.length && hits[0].got >= Math.max(1, Math.ceil(r.qs.length * 0.5));
      var show = function (text) {
        a.textContent = "";
        if (text) { a.appendChild(h("span", "ask-tag", T.ai)); paragraphs(a, text); a.appendChild(h("small", "", T.aiNote)); }
        else if (strong) { a.appendChild(h("h5", "", hits[0].d.h)); a.appendChild(h("p", "", excerpt(hits[0].d, r.terms))); }
        else { a.appendChild(h("p", "", T.none)); }
        if (strong) { a.appendChild(link(hits[0].d, hits[0].d.el ? T.here : hits[0].d.p, T.open)); if (hits.length > 1) { a.appendChild(h("small", "", T.more)); hits.slice(1).forEach(function (x) { a.appendChild(link(x.d)); }); } }
        else { var heads = {}, n = 0; (hits.length ? hits.map(function (x) { return x.d; }) : docs).forEach(function (d) { if (!heads[d.u] && n < 3 && d.h) { heads[d.u] = 1; n++; a.appendChild(link(d)); } }); }
        done();
      };
      if (ai) { wait.textContent = ""; wait.className = "ask-dots"; askAI(q, strong ? hits : []).then(show); } else show("");
    });
  }
  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", build); else build();
})();
