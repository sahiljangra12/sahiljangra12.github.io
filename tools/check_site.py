#!/usr/bin/env python3
"""Health check for the site. Exits non-zero when something would make it slow or broken.

Run:  python3 tools/check_site.py
Checks: the app page stays small, no images are embedded in it, every local file it
points to exists, every address has its page, and each address's view exists in the app.
"""
import os, re, sys, json
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'docs')
MAX_APP_KB = 900          # docs/portfolio.html
MAX_CSS_KB = 120          # docs/portfolio-hud.css
MAX_IMAGE_KB = 600        # any single image the app page loads
problems, notes = [], []

app_path = os.path.join(ROOT, 'portfolio.html')
app = open(app_path, encoding='utf-8').read()
kb = os.path.getsize(app_path) / 1024
(problems if kb > MAX_APP_KB else notes).append('portfolio.html is %.0f KB (limit %d KB)' % (kb, MAX_APP_KB))
css_kb = os.path.getsize(os.path.join(ROOT, 'portfolio-hud.css')) / 1024
(problems if css_kb > MAX_CSS_KB else notes).append('portfolio-hud.css is %.0f KB (limit %d KB)' % (css_kb, MAX_CSS_KB))

embedded = re.findall(r'data:(?:image|font|application)/[a-z0-9.+-]+;base64,[A-Za-z0-9+/=]{3000,}', app)
if embedded:
    problems.append('%d embedded data: files in portfolio.html (%.0f KB). Save them under docs/assets/ and link them.' % (len(embedded), sum(map(len, embedded)) / 1024))

missing, heavy = set(), []
for ref in set(re.findall(r'(?:src|href)="(/[^"#?]+)', app)) | set(re.findall(r'url\((/[^)"\'?#]+)', app)):
    if ref.startswith('//'):
        continue
    p = os.path.join(ROOT, ref.lstrip('/'))
    if os.path.isdir(p):
        p = os.path.join(p, 'index.html')
    if not os.path.exists(p):
        missing.add(ref)
    elif re.search(r'\.(png|jpe?g|webp|gif)$', ref, re.I) and os.path.getsize(p) / 1024 > MAX_IMAGE_KB:
        heavy.append('%s (%.0f KB)' % (ref, os.path.getsize(p) / 1024))
if missing:
    problems.append('missing files referenced by portfolio.html: ' + ', '.join(sorted(missing)[:12]))
if heavy:
    problems.append('images over %d KB: %s' % (MAX_IMAGE_KB, ', '.join(heavy[:8])))

routes_path = os.path.join(ROOT, 'assets', 'routes.json')
if os.path.exists(routes_path):
    routes = json.load(open(routes_path, encoding='utf-8'))
    ids = set(re.findall(r'\bid="([^"]+)"', app))
    for key, path in list(routes['views'].items()) + list(routes['overlays'].items()):
        if key != 'top' and key not in ids:
            problems.append('address %s points at #%s, which is not in portfolio.html' % (path, key))
        if not os.path.exists(os.path.join(ROOT, path.strip('/'), 'index.html')):
            problems.append('address %s has no page; run tools/build_pages.py' % path)
    for pid in set(re.findall(r'<p class="study-tag[^"]*" id="(s-[a-z0-9-]+)"', app)):
        if pid not in routes['views']:
            problems.append('project #%s has no address; add it to PROJECTS in tools/build_pages.py' % pid)
else:
    problems.append('docs/assets/routes.json is missing; run tools/build_pages.py')

for n in notes:
    print('ok   ', n)
for p in problems:
    print('FAIL ', p)
print('%d problem(s)' % len(problems))
sys.exit(1 if problems else 0)
