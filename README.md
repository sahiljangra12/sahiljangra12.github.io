# sahiljangra12.github.io

Personal research site of **Sahil** — data science and research on sustainability, climate, health and development (Johns Hopkins University, MSE Data Science).

Live at **https://sahiljangra12.github.io**

## How the site is put together

- `docs/` is the published site (GitHub Pages source).
- `docs/portfolio.html` is the site itself: one app document holding every page. `docs/portfolio-hud.css` is its theme.
- Every public address (`/`, `/education/`, `/research/`, `/research/<project>/`, `/explorer/`, `/commentary/`, `/about/`, `/contact/`, `/writing/`) is a small page that carries that page's title, description and link-preview tags, a plain readable copy of the text, and a full-screen frame that loads the app at the matching view. These pages, `404.html`, `sitemap.xml` and `robots.txt` are **generated**: do not edit them by hand.
- After changing text in `docs/portfolio.html`, run `python3 tools/build_pages.py` (needs `beautifulsoup4` and `lxml`) and commit the result. Addresses are listed in `ROUTES`/`PROJECTS` at the top of that script; add a new project there.
- Keep `docs/portfolio.html` light: put images in `docs/assets/` and link them (no embedded `data:` images), and keep large data in `docs/assets/data/`.
- Inside the app, links between pages are `#` links (`#education`, `#s-asda`, `#writing`); the app keeps the address bar on the matching real address. Old `/#education` style links still work.
- `docs/policyaudit/` and `docs/research/policyaudit/` are the separate PolicyAudit app. `docs/assets/index-*.js` and `styles-*.css` belong to it.
- The `fui-redesign` branch keeps the earlier hand-built redesign.
