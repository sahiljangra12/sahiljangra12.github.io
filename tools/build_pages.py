#!/usr/bin/env python3
"""Build the small address pages around docs/portfolio.html.

The site itself is one app document, docs/portfolio.html. Every public
address (/, /education/, /research/<project>/ ...) is a small page that
  * carries that page's own title, description and link-preview tags,
  * holds a plain, readable copy of the page text (shown until the app
    loads, and readable by search engines), and
  * loads the app in a full-screen frame at the matching view.

Run after changing text in docs/portfolio.html:   python3 tools/build_pages.py
It rewrites docs/index.html, docs/404.html, docs/sitemap.xml, docs/robots.txt
and docs/<address>/index.html for every address in ROUTES.
"""
import html, json, os, re, sys
from bs4 import BeautifulSoup, NavigableString

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'docs')
SITE = 'https://sahiljangra12.github.io'
OG_IMAGE = SITE + '/assets/social/sahil-preview.png'
NAME = 'Sahil'

PROJECTS = [  # id in the app, address slug
    ('s-grid', 'grid-data-centers'), ('s-asda', 'asda-lab'), ('s-krishi', 'krishi-mitra-haryana'),
    ('s-billback', 'billback-baltimore'), ('s-neural', 'neural-network-lab'), ('s-charm', 'charm-city-pulse'),
    ('s-policyaudit', 'policy-audit'), ('s-basket', 'basket-compare'), ('s-claimback', 'claimback'),
    ('s-trees', 'street-trees'), ('s-heat', 'baltimore-heat-atlas'), ('s-climate', 'social-shortfall-climate-overshoot'),
    ('s-thesis', 'planetary-boundaries'), ('s-energy', 'energy-transition'), ('s-sdg', 'sdg-explorer-india'),
    ('s-bluejay', 'blue-jay-buddy'), ('s-aisearch', 'search-adversarial-agent'),
]
# app hash -> address
PATHS = {'top': '/', 'education': '/education/', 'research': '/research/', 'sustainability-explorer': '/explorer/',
         'commentary': '/commentary/', 'about': '/about/', 'contact': '/contact/'}
PATHS.update({pid: '/research/%s/' % slug for pid, slug in PROJECTS})
# full-screen pages that have an address of their own
OVERLAY_PATHS = {'writing': '/writing/', 'tree-cooling': '/research/baltimore-street-trees/'}

DESCRIPTIONS = {
    'top': "Sahil is a Data Science graduate student at Johns Hopkins University. Research and open tools on climate, cities and development.",
    'education': "Sahil's education: MSE in Data Science at Johns Hopkins University (2026-2028) and B.S. (Honours with Research) in Analytics and Sustainability Studies at TISS Mumbai.",
    'research': "Research studies, working papers and open tools by Sahil: power grids and data centers, Baltimore heat and street trees, climate overshoot, statistics labs and more.",
    'sustainability-explorer': "Global Sustainability Explorer: a free, open tool to explore, compare and cite data for all 17 Sustainable Development Goals.",
    'commentary': "Commentary by Sahil on prediction, lived experience and whose goals a model serves.",
    'about': "About Sahil: research assistant at Johns Hopkins University, research intern at Good Business Lab, fieldwork in Maharashtra and Varanasi, skills and projects.",
    'contact': "Contact Sahil: email, LinkedIn, GitHub and Instagram. Baltimore, Maryland.",
    'writing': "Papers, reports and commentary by Sahil in one place.",
    'tree-cooling': "Do new street trees cool Baltimore? A working paper with within-neighborhood evidence from Baltimore's street-tree program, 2006-2025.",
}
TITLES = {'top': 'Sahil — Data Science & Research', 'education': 'Education', 'research': 'Research & Projects',
          'sustainability-explorer': 'Global Sustainability Explorer', 'commentary': 'Commentary', 'about': 'About me',
          'contact': 'Contact', 'writing': 'Writing', 'tree-cooling': 'Do New Street Trees Cool Baltimore?'}


def clean(node, hash_to_path):
    """Plain, safe HTML copy of a content block: headings, text, lists and links only."""
    out = []
    KEEP = {'h1': 'h2', 'h2': 'h2', 'h3': 'h3', 'h4': 'h3', 'p': 'p', 'li': 'li', 'figcaption': 'p', 'summary': 'p', 'blockquote': 'p'}

    def inline(el):
        parts = []
        for c in el.children:
            if isinstance(c, NavigableString):
                parts.append(html.escape(str(c)))
            elif c.name in ('script', 'style', 'svg', 'canvas', 'template', 'img', 'button', 'select', 'input', 'iframe'):
                continue
            elif c.name == 'a' and c.get('href'):
                href = c['href']
                if href.startswith('#'):
                    href = hash_to_path.get(href[1:])
                txt = inline(c).strip()
                if txt and href and not href.startswith('javascript'):
                    parts.append('<a href="%s">%s</a>' % (html.escape(href, quote=True), txt))
                elif txt:
                    parts.append(txt)
            elif c.name == 'br':
                parts.append(' ')
            else:
                parts.append(inline(c))
        return re.sub(r'\s+', ' ', ''.join(parts))

    seen = set()
    for el in node.find_all(list(KEEP)):
        if el.find_parent(['template', 'script', 'style', 'svg']):
            continue
        if any(p.name in KEEP and p is not node for p in el.parents if p is not None and getattr(p, 'name', None)):
            # nested block (e.g. p inside li): let the outer one carry the text
            if el.find_parent(list(KEEP)):
                continue
        txt = inline(el).strip()
        key = re.sub(r'<[^>]+>', '', txt)
        if len(key) < 2 or key in seen:
            continue
        seen.add(key)
        out.append('<%s>%s</%s>' % (KEEP[el.name], txt, KEEP[el.name]))
    # group consecutive li into ul
    res, buf = [], []
    for line in out:
        if line.startswith('<li>'):
            buf.append(line)
        else:
            if buf:
                res.append('<ul>' + ''.join(buf) + '</ul>'); buf = []
            res.append(line)
    if buf:
        res.append('<ul>' + ''.join(buf) + '</ul>')
    return '\n'.join(res)


SHELL_CSS = ("html,body{margin:0;min-height:100%;background:#07080c;color:#e9ecf2;font:16px/1.65 Inter,-apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif}"
             "#app{position:fixed;inset:0;width:100%;height:100%;border:0;z-index:2;background:transparent}"
             ".fb{max-width:760px;margin:0 auto;padding:28px 22px 80px}.fb h1{font-size:30px;line-height:1.2;margin:18px 0 10px}.fb h2{font-size:22px;margin:28px 0 8px}.fb h3{font-size:18px;margin:22px 0 6px}"
             ".fb p,.fb li{color:#b9c0cd}.fb a{color:#9cc2ff}.fb nav{display:flex;flex-wrap:wrap;gap:8px 16px;font-size:14px;padding:6px 0 14px;border-bottom:1px solid #222838}.fb nav a{color:#e9ecf2;text-decoration:none}"
             ".l,.l body{background:#fbfaf7;color:#12151c}.l .fb p,.l .fb li{color:#4b5566}.l .fb a{color:#1d4fa8}.l .fb nav{border-color:#dfe3ea}.l .fb nav a{color:#12151c}")

SHELL_JS = ("(function(){var f=document.getElementById('app'),m=document.querySelector('.fb');"
            "f.addEventListener('load',function(){if(m){m.setAttribute('aria-hidden','true');m.inert=true}});"
            "window.__paths=%s;})();")


def page(path, app_hash, title, desc, body_html, nav_html, jsonld=None, noindex=False):
    full_title = title if app_hash == 'top' else '%s · %s' % (title, NAME)
    url = SITE + path
    head = [
        '<!doctype html><html lang="en"><head><meta charset="utf-8">',
        '<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">',
        '<title>%s</title>' % html.escape(full_title),
        '<meta name="description" content="%s">' % html.escape(desc, quote=True),
        '<meta name="author" content="Sahil">',
        '<meta name="robots" content="noindex">' if noindex else '<link rel="canonical" href="%s">' % url,
        '<meta name="theme-color" content="#07080c">',
        '<link rel="icon" href="/favicon.png" type="image/png">',
        '<meta property="og:type" content="website"><meta property="og:site_name" content="Sahil Lab">',
        '<meta property="og:title" content="%s">' % html.escape(full_title, quote=True),
        '<meta property="og:description" content="%s">' % html.escape(desc, quote=True),
        '<meta property="og:url" content="%s">' % url,
        '<meta property="og:image" content="%s"><meta property="og:image:width" content="1200"><meta property="og:image:height" content="630">' % OG_IMAGE,
        '<meta property="og:image:alt" content="Sahil — Data Science and Research, Johns Hopkins University">',
        '<meta name="twitter:card" content="summary_large_image">',
        '<meta name="twitter:title" content="%s">' % html.escape(full_title, quote=True),
        '<meta name="twitter:description" content="%s">' % html.escape(desc, quote=True),
        '<meta name="twitter:image" content="%s">' % OG_IMAGE,
        '<link rel="preload" href="/portfolio-hud.css" as="style">',
        '<style>%s</style>' % SHELL_CSS,
        "<script>try{if(localStorage.getItem('sahil-theme')==='light')document.documentElement.className='l'}catch(e){}</script>",
    ]
    if jsonld:
        head.append('<script type="application/ld+json">%s</script>' % json.dumps(jsonld, ensure_ascii=False))
    head.append('</head><body>')
    src = '/portfolio.html' + ('' if app_hash == 'top' else '#' + app_hash)
    body = ['<main class="fb"><nav aria-label="Pages">%s</nav><h1>%s</h1>\n%s\n</main>' % (nav_html, html.escape(title), body_html),
            '<iframe id="app" src="%s" title="%s" allow="clipboard-write; fullscreen" allowfullscreen></iframe>' % (src, html.escape(full_title, quote=True)),
            '<script>%s</script>' % (SHELL_JS % json.dumps({'views': PATHS, 'overlays': OVERLAY_PATHS})),
            '<script data-goatcounter="https://sahillab.goatcounter.com/count" async src="//gc.zgo.at/count.js"></script>',
            '</body></html>']
    return '\n'.join(head + body)


def main():
    soup = BeautifulSoup(open(os.path.join(ROOT, 'portfolio.html'), encoding='utf-8').read(), 'lxml')
    hash_to_path = dict(PATHS); hash_to_path.update(OVERLAY_PATHS); hash_to_path['home-intro'] = '/'
    nav = ''.join('<a href="%s">%s</a>' % (PATHS[k], t) for k, t in (('top', 'Home'), ('education', 'Education'), ('research', 'Research'),
                  ('sustainability-explorer', 'Explorer'), ('commentary', 'Commentary'), ('about', 'About me'), ('contact', 'Contact'))) + '<a href="/writing/">Writing</a>'
    out = {}

    def sec(i):
        return soup.find(id=i)

    # home
    home = BeautifulSoup('<div></div>', 'lxml').div
    for part in (soup.find(id='top'), soup.find(id='home-intro')):
        if part is not None:
            home.append(BeautifulSoup(str(part), 'lxml'))
    person = {"@context": "https://schema.org", "@type": "Person", "name": "Sahil", "url": SITE + "/",
              "image": SITE + "/assets/profile/sahil-portrait.webp", "jobTitle": "Graduate student, MSE Data Science",
              "affiliation": {"@type": "CollegeOrUniversity", "name": "Johns Hopkins University"},
              "alumniOf": {"@type": "CollegeOrUniversity", "name": "Tata Institute of Social Sciences"},
              "email": "mailto:sfnu1@jh.edu",
              "sameAs": ["https://www.linkedin.com/in/sahil-j-3b5322261", "https://github.com/sahiljangra12", "https://www.instagram.com/sahil.j12/"]}
    tiles = soup.select('#home-intro .home-tile')
    tile_list = '<ul>' + ''.join('<li><a href="%s">%s</a> — %s</li>' % (
        hash_to_path.get(a['href'][1:], a['href']) if a['href'].startswith('#') else a['href'],
        html.escape(a.find('strong').get_text(' ', strip=True)), html.escape(a.find_all('span')[-1].get_text(' ', strip=True))) for a in tiles) + '</ul>'
    out['/'] = page('/', 'top', TITLES['top'], DESCRIPTIONS['top'], clean(home, hash_to_path) + '\n' + tile_list, nav, jsonld=person)

    for key in ('education', 'commentary', 'about', 'contact'):
        out[PATHS[key]] = page(PATHS[key], key, TITLES[key], DESCRIPTIONS[key], clean(sec(key), hash_to_path), nav)

    # research index and one page per project
    wrap = sec('research').find(class_='wrap')
    groups, cur = {}, None
    names = {}
    for ch in wrap.find_all(recursive=False):
        cls = ch.get('class') or []
        if 'section-head' in cls or 'poster-index' in cls or 'proj-back' in cls:
            continue
        if ch.name == 'p' and 'study-tag' in cls and ch.get('id'):
            cur = ch['id']
            names[cur] = re.sub(r'^\s*New\s+', '', ch.get_text(' ', strip=True))
        elif ch.get('id') == 'sustainability-explorer':
            cur = 'sustainability-explorer'
        if cur:
            groups.setdefault(cur, []).append(ch)
    idx = ['<p>%s</p>' % html.escape(wrap.find(class_='section-head').find('p').get_text(' ', strip=True)), '<ul>']
    for a in wrap.find(class_='poster-index').find_all('a'):
        pid = a['href'][1:]
        label = a.get('aria-label') or a.get_text(' ', strip=True)
        small = a.find('small')
        idx.append('<li><a href="%s">%s</a>%s</li>' % (PATHS.get(pid, '/research/'), html.escape(label), ' — ' + html.escape(small.get_text(' ', strip=True)) if small else ''))
    idx.append('</ul>')
    credits = sec('data-credits')
    out['/research/'] = page('/research/', 'research', TITLES['research'], DESCRIPTIONS['research'], '\n'.join(idx) + ('\n' + clean(credits, hash_to_path) if credits else ''), nav)
    for pid, els in groups.items():
        box = BeautifulSoup('<div></div>', 'lxml').div
        for e in els:
            if e.name == 'p' and 'study-tag' in (e.get('class') or []):
                continue
            box.append(BeautifulSoup(str(e), 'lxml'))
        body = clean(box, hash_to_path)
        if pid == 'sustainability-explorer':
            title, desc = TITLES[pid], DESCRIPTIONS[pid]
        else:
            title = names.get(pid, pid)
            paras = [re.sub(r'<[^>]+>', '', m) for m in re.findall(r'<p>(.*?)</p>', body, re.S)]
            paras = [x for x in paras if len(x) > 60]
            desc = paras[0] if paras else title
            desc = (desc[:197].rsplit(' ', 1)[0] + '…') if len(desc) > 200 else desc
        if pid not in PATHS:
            print('warning: no address for', pid, file=sys.stderr); continue
        out[PATHS[pid]] = page(PATHS[pid], pid, title, html.unescape(desc), '<p><a href="/research/">← All research &amp; projects</a></p>\n' + body, nav)

    for oid, path in OVERLAY_PATHS.items():
        el = sec(oid)
        out[path] = page(path, oid, TITLES[oid], DESCRIPTIONS[oid], clean(el, hash_to_path) if el else '', nav)

    for path, doc in out.items():
        d = os.path.join(ROOT, path.strip('/'))
        os.makedirs(d, exist_ok=True)
        open(os.path.join(d, 'index.html'), 'w', encoding='utf-8').write(doc)
    # unknown addresses: show the home page, do not index
    open(os.path.join(ROOT, '404.html'), 'w', encoding='utf-8').write(
        page('/', 'top', 'Page not found', 'This address does not exist. Here is the home page.', '<p>That page does not exist. <a href="/">Go to the home page</a>.</p>', nav, noindex=True))
    urls = sorted(out)
    open(os.path.join(ROOT, 'sitemap.xml'), 'w', encoding='utf-8').write(
        '<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n' +
        ''.join('  <url><loc>%s%s</loc></url>\n' % (SITE, u) for u in urls) + '</urlset>\n')
    open(os.path.join(ROOT, 'robots.txt'), 'w', encoding='utf-8').write('User-agent: *\nAllow: /\n\nSitemap: %s/sitemap.xml\n' % SITE)
    json.dump({'views': PATHS, 'overlays': OVERLAY_PATHS, 'titles': {k: v for k, v in TITLES.items()}, 'projects': names},
              open(os.path.join(ROOT, 'assets', 'routes.json'), 'w', encoding='utf-8'), ensure_ascii=False)
    print('built', len(out), 'pages:', ' '.join(urls))


if __name__ == '__main__':
    main()
