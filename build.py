"""Builds the static site pages from the content below. Run: python3 build.py"""
import os

ROOT = os.path.dirname(os.path.abspath(__file__))
L = "https://sahil-ams-ds.lovable.app"          # files still hosted on the Lovable site
GH = "https://github.com/sahiljangra12"
IO = "https://sahiljangra12.github.io"
CV = "papers/CV_Sahil.pdf"
EMAIL = "sfnu1@jh.edu"
LINKEDIN = "https://www.linkedin.com/in/sahil-j-3b5322261"
EXT = ' target="_blank" rel="noopener"'


def head(title, desc, base=""):
    return f"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{title}</title>
<meta name="description" content="{desc}">
<meta name="author" content="Sahil">
<meta property="og:title" content="{title}">
<meta property="og:description" content="{desc}">
<meta property="og:type" content="website">
<meta property="og:image" content="{IO}/assets/img/og.jpg">
<meta name="twitter:card" content="summary_large_image">
<meta name="theme-color" content="#04060c">
<link rel="icon" href="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 64 64'%3E%3Crect width='64' height='64' rx='14' fill='%2304060c'/%3E%3Cpath d='M44 18c-3-4-8-6-13-6-8 0-13 5-13 11 0 14 28 7 28 21 0 6-6 10-14 10-6 0-11-2-14-7' fill='none' stroke='%2341e0b5' stroke-width='6' stroke-linecap='round'/%3E%3C/svg%3E">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&family=JetBrains+Mono:wght@400;600;700&display=swap" rel="stylesheet">
<link rel="stylesheet" href="{base}assets/css/site.css">
</head>
<body>
<a class="skip" href="#main">Skip to content</a>
<canvas id="stars" aria-hidden="true"></canvas>
"""


def nav(base="", home=True):
    p = "" if home else base + "index.html"
    items = [("Writing", base + "writing.html"), ("Education", "#education"), ("Research", "#research"), ("Commentary", "#commentary"), ("About", base + "about.html"), ("Contact", "#contact")]
    lis = "".join(f'<li><a class="navlink" href="{h if h.endswith(".html") else p + h}">{t}</a></li>' for t, h in items)
    return f"""<header class="nav">
<a class="brand" href="{base}index.html#top" aria-label="Sahil Lab, home"><img src="{base}assets/img/sahil-lab-logo.png" alt="" width="120" height="30"></a>
<button class="menu-btn" aria-expanded="false" aria-controls="nav-list" aria-label="Open menu"><svg width="20" height="20" viewBox="0 0 20 20" aria-hidden="true"><path d="M2 5h16M2 10h16M2 15h16" stroke="currentColor" stroke-width="2"/></svg></button>
<nav aria-label="Main"><ul id="nav-list">{lis}<li><a class="navlink" href="{base}{CV}">CV ↗</a></li></ul></nav>
</header>
"""


def foot(base=""):
    return f"""<footer><div class="wrap">
<span class="code">© 2026 Sahil · Baltimore, Maryland</span>
<span class="code"><a href="{GH}"{EXT}>GitHub</a> · <a href="{LINKEDIN}"{EXT}>LinkedIn</a> · <a href="mailto:{EMAIL}">Email</a></span>
</div></footer>
<script src="{base}assets/js/site.js" defer></script>
</body>
</html>
"""


def hud(code, eyebrow, title, lede=""):
    lede = f'<p class="lede">{lede}</p>' if lede else ""
    return f"""<div class="hud-head reveal"><span class="code">{code}</span><p class="eyebrow">{eyebrow}</p><h2>{title}</h2>{lede}<span class="ruler" aria-hidden="true"></span></div>"""


# ------------------------------------------------------------------ projects
PROJECTS = [
    dict(id="s-neural", art="neural-network-lab", accent="#ff5a4f", badge="NEW", label="Interactive machine learning · Browser-based lab", idx="NEW · INTERACTIVE ML LAB", name="Neural Network Lab",
         title="See a neural network learn.",
         lead="Choose a dataset, design the architecture and launch training. Watch weights, decision boundaries and loss change as the network learns — then test your intuition through 11 guided missions.",
         kicker="Build it. Train it. Understand it.", sub="A hand-written JavaScript network with no libraries, supporting both classification and regression entirely in your browser.",
         cta=("Open lab", IO + "/neural-network-lab/"),
         res=[("ACADEMY", "Neurons, loss & backprop ↗", IO + "/neural-network-lab/learn.html"), ("MISSIONS", "Begin 11 guided exercises ↗", IO + "/neural-network-lab/?challenge=1"),
              ("REPORT", "Technical report (PDF) ↗", "papers/neural-network-lab-technical-report.pdf"), ("CODE", "GitHub repository ↗", GH + "/neural-network-lab")],
         tags="Interactive teaching tool · Classification + regression · Runs locally in your browser"),
    dict(id="s-pulse", art="charm-city-pulse", accent="#ffd23f", label="Baltimore · Live environment & open data", idx="LIVE CITY TOOL", name="Charm City Pulse",
         title="Your city. Today.<br>Your neighborhood, in context.",
         lead="Is it a good day to be outside? What does heat, flood risk or access to help look like on your block? Charm City Pulse connects live conditions with neighborhood evidence — with a simple view for residents and deeper tools for researchers.",
         kicker="From a daily question to the underlying data.", sub="Weather, air quality, alerts, maps and public resources. Explore uncertainty, compare places and download the evidence.",
         cta=("Open app", IO + "/charm-city-pulse/"),
         res=[("OVERVIEW", "Methods & refresh schedule ↗", GH + "/charm-city-pulse#readme"), ("CODE", "GitHub repository ↗", GH + "/charm-city-pulse"), ("RESULTS", "Explore the indicators ↗", IO + "/charm-city-pulse/#explore")],
         tags="Live feeds + daily source releases · Not a substitute for official alerts; call 311 to confirm center availability."),
    dict(id="s-policyaudit", art="policyaudit", accent="#41e0b5", label="Causal AI · Open research tool", idx="RESEARCH TOOL", name="PolicyAudit",
         title="Your model worked there. Does it work here?",
         lead="When a treatment-targeting model moves to a new setting, should its decisions change? PolicyAudit uses a small randomized pilot to compare the existing policy with recalibrated alternatives — and makes uncertainty part of the answer.",
         kicker="Keep, recalibrate, or collect more.", sub="A decision aid based on average benefit, not a judgement about an individual.",
         cta=("Open audit tool", L + "/research/policyaudit"),
         res=[("MANUAL", "Method & validation ↗", L + "/__l5e/assets-v1/c99d0db8-79ed-42fa-8bf9-73922aa30bda/policyaudit_manual.pdf"),
              ("CODE", "Python package ↓", L + "/__l5e/assets-v1/c3196e17-cdbf-463f-8d18-a609949648f2/policyaudit_v0.1.0.zip"),
              ("RESULTS", "Simulations & assumptions ↗", L + "/research/policyaudit#method")],
         ci=True, tags="Cross-fitted AIPW · Confidence bounds · Browser-only CSV analysis"),
    dict(id="s-trees", art="baltimore-tree-cooling", accent="#9ae6ff", label="Working paper · October 2026", idx="OCTOBER 2026", name="Do New Street Trees Cool Baltimore?",
         title="Do New Street Trees Cool Baltimore?",
         lead="Do newly planted trees make a street cooler, or were greener places already cooling? I compared nearby blocks over time. The evidence points to a small drop in summer surface temperature as young trees grow.",
         stats=[("0.026 °C", "less surface heat per young tree"), ("2022–25", "estimate period"), ("p = 0.63", "no pre-planting trend")],
         statnote="Estimated for 2022–25 · Not a measure of air temperature",
         cta=("Explore the study", "research/baltimore-street-trees.html"),
         res=[("PAPER", "Read the PDF ↗", "papers/baltimore-street-tree-paper.pdf"), ("CODE", "GitHub repository ↗", GH + "/baltimore-tree-cooling")],
         tags="Causal inference · Urban heat · Remote sensing · Python"),
    dict(id="s-heat", art="baltimore-heat-atlas", accent="#ffb347", label="Working paper · Baltimore City · October 2026", idx="2026", name="Baltimore Heat Atlas",
         title="Where heat meets vulnerability.",
         lead="Satellite heat, health estimates and social conditions meet in a neighbourhood-level atlas of Baltimore. Explore where exposure and limited resources overlap — and how confidently those places can be identified.",
         cta=("Open dashboard", IO + "/baltimore-heat-atlas/"),
         res=[("PAPER", "Read the PDF ↗", "papers/baltimore-heat-vulnerability.pdf"), ("CODE", "GitHub repository ↗", GH + "/baltimore-heat-atlas"), ("RESULTS", "Interactive dashboard ↗", IO + "/baltimore-heat-atlas/")],
         findings=["Average summer daytime surface temperature ranges from 35.7 to 47.5 °C across scored tracts.",
                   "ZIP-area heat vulnerability is associated with heat-related EMS activations (ρ = 0.69); this is not a causal estimate.",
                   "Rank uncertainty is visible: 27 tracts remain in the most vulnerable fifth in at least 90% of simulations."],
         tags="GIS · Remote sensing · Spatial statistics · Health validation · Uncertainty analysis"),
    dict(id="s-shortfall", art="planetary-pathways", accent="#41e0b5", label="Working paper · Johns Hopkins · 1990–2022", idx="JHU · 1990–2022", name="Social shortfall & climate overshoot",
         title="Can basic needs be met within the climate boundary?",
         lead="A country-year panel comparing four social thresholds (life expectancy, under-5 mortality, electricity access and employment) with consumption-based CO<sub>2</sub>, measured against a fair-share boundary of 1.61 t per person per year.",
         cta=("Open dashboard", IO + "/planetary-pathways/"),
         res=[("PAPER", "Read the PDF ↗", "papers/social-shortfall-climate-overshoot.pdf"), ("CODE", "GitHub repository ↗", GH + "/planetary-pathways"), ("RESULTS", "Interactive dashboard ↗", IO + "/planetary-pathways/")],
         findings=["No country with consumption-based estimates met all four social thresholds within the boundary in any year.",
                   "The pooled-trend carbon requirement fell from about 26 t (1991) to 8.5 t (2022), still 5.3 times the boundary.",
                   "Absolute decoupling spread to 48 countries in 2011–2022, but only 2 of 41 decouplers above the boundary cut fast enough to reach it by 2050."],
         tags="Python · Panel data · Logistic models · Decoupling analysis · Descriptive associations, not causal effects"),
    dict(id="s-gse", art="global-sustainability-explorer", accent="#b6f36b", badge="FEATURED", label="Open tool · 2026 · All 17 SDGs", idx="FEATURED · 2026", name="Global Sustainability Explorer",
         title="Seventeen goals. Every country. One place.",
         lead="A free, open tool for researchers to explore, compare and cite global sustainability data for all 17 Sustainable Development Goals in one place. It brings together the UN SDG Global Database, the World Bank's World Development Indicators and Our World in Data, updates itself as new releases come out, and follows sustainability news from the UN and its conferences.",
         cta=("Open dashboard", IO + "/global-sustainability-explorer/"),
         res=[("PAPER", "Project overview ↗", GH + "/global-sustainability-explorer#readme"), ("CODE", "GitHub repository ↗", GH + "/global-sustainability-explorer"), ("RESULTS", "Interactive dashboard ↗", IO + "/global-sustainability-explorer/")],
         findings=["<b>Drill down by goal.</b> Goal → target → indicator → breakdown (sex, age, urban/rural), for any country, region or year range.",
                   "<b>Always current.</b> An automated pipeline checks every source every few hours, downloads only what changed, validates it and logs each update.",
                   "<b>Chart, map, table.</b> Compare countries over time, play a world map through the years, and download CSV with source columns.",
                   "<b>Live news and conferences.</b> Headlines from UN and specialist newsrooms tagged by SDG and country, with UN conferences such as COP31 tracked."],
         tags="Python · pandas · DuckDB / Parquet · GitHub Actions · JavaScript · Observable Plot · GitHub Pages · Data: UN SDG Global Database, World Bank WDI and Our World in Data, each under its own licence."),
    dict(id="s-thesis", art="thesis", accent="#f4b740", label="Undergraduate thesis · TISS · 1990–2023", idx="THESIS · 1990–2023", name="Planetary boundaries & development",
         title="Development.<br>At what planetary cost?",
         kicker="Planetary Boundary Transgressions and Divergent Socio-Economic Pathways", sub="A Cross-National Quantitative Analysis · Supervisor: Dr. Kamal Kumar Murari, TISS",
         lead="Do better living conditions come with greater environmental pressure? My thesis examines world-level patterns across three decade-scale study periods, exploring how development and selected environmental pressures are associated over time.",
         stats=[("World-level", "environmental pressure & development"), ("4", "development–pressure profiles"), ("0.40 → 0.25", "pressure–life expectancy correlation weakens over time")],
         statnote="Country-period observations, not annual measurements. Associations do not establish causation.",
         cta=("Open dashboard", IO + "/Thesis/"),
         res=[("RESOURCES", "Thesis overview ↗", GH + "/Thesis#readme"), ("CODE", "GitHub repository ↗", GH + "/Thesis"), ("RESULTS", "Interactive dashboard ↗", IO + "/Thesis/")]),
    dict(id="s-energy", art="energy-transition-analysis", accent="#35d07f", label="Research · 2000–2021", idx="2000–2021", name="Energy transition & development",
         title="Energy Transition and Development",
         lead="How has renewable energy grown across the globe since 2000, and how does it relate to national income? A tested Python pipeline from raw World Bank and UN SDG 7.2.1 data to results, figures and an interactive dashboard.",
         cta=("Open dashboard", IO + "/energy-transition-analysis/"),
         res=[("PAPER", "Technical report ↗", "papers/energy-transition-report.pdf"), ("CODE", "GitHub repository ↗", GH + "/energy-transition-analysis"), ("RESULTS", "Interactive dashboard ↗", IO + "/energy-transition-analysis/")],
         findings=["Holding the same 187 countries fixed, the median renewable share of electricity rose from 10.3% in 2000 to 22.0% in 2021.",
                   "For all final energy, the renewable share falls steeply with income (ρ = −0.56); for electricity the link is weak (ρ = −0.17).",
                   "74% of the 151 countries with more than 1 million people increased their renewable electricity share between 2011 and 2021.",
                   "Low-share countries are catching up, even after controlling for income and region."],
         tags="Python · World Bank & UN SDG data · Regression · Plotly"),
    dict(id="s-sdgindia", art="sdg-explorer-india", accent="#ff9933", label="Research · India · 17 SDGs", idx="INDIA · 17 SDGS", name="SDG Explorer India",
         title="SDG Explorer India",
         lead="How is India doing on all 17 UN Sustainable Development Goals, and where is data missing? An explorer built from four official sources (UN SDG database, MoSPI, NITI Aayog and NFHS), from national series back to 1977 down to 704 districts. Every value links to its official source, and gaps are shown, never filled.",
         cta=("Open dashboard", IO + "/sdg-explorer-india/"),
         res=[("PAPER", "Methods note ↗", GH + "/sdg-explorer-india/blob/main/docs/METHODS.md"), ("CODE", "GitHub repository ↗", GH + "/sdg-explorer-india"), ("RESULTS", "Interactive dashboard ↗", IO + "/sdg-explorer-india/")],
         findings=["Follow each goal over time with official values, exactly as published.",
                   "Compare States, Union Territories and districts side by side.",
                   "See clearly where India's data is missing, rather than filled in."],
         tags="Python · PDF table extraction · Data validation · Plotly"),
    dict(id="s-bluejay", art="blue-jay-buddy", accent="#7fb0ff", label="Johns Hopkins · Student companion", idx="JHU · STUDENT TOOL", name="Blue Jay Buddy",
         title="Blue Jay Buddy",
         lead="Hopkins, made simple. Classes, deadlines, shuttles, food and safety in one place, with step-by-step guides — no login, and your details stay on your device. Paste a private Canvas calendar link to see every deadline, upload a schedule screenshot for “up next”, and get a checklist made for your program.",
         cta=("Open app", IO + "/blue-jay-buddy/"),
         res=[("LIVE", "Open the app ↗", IO + "/blue-jay-buddy/"), ("CODE", "GitHub repository ↗", GH + "/blue-jay-buddy")],
         findings=["Live shuttle arrivals and the nearest stops, with location kept on-device.",
                   "Canvas deadlines, dining and library hours, and campus events in one view.",
                   "Late-night safety: Night Ride, safety escort and 24/7 crisis line one tap away."],
         tags="Built by a student, for students · No login · Works on phone and laptop"),
]


def is_ext(u):
    return u.startswith("http")


def a_attrs(u):
    return EXT if is_ext(u) else ""


def project_html(p, n):
    badge = f'<span class="badge">{p["badge"]}</span>' if p.get("badge") else ""
    kicker = f'<p class="kicker">{p["kicker"]}</p><p>{p["sub"]}</p>' if p.get("kicker") else ""
    stats = ""
    if p.get("stats"):
        stats = '<div class="stats">' + "".join(f"<div><b>{a}</b><small>{b}</small></div>" for a, b in p["stats"]) + "</div>"
        stats += f'<p class="note" style="margin-top:10px">{p["statnote"]}</p>'
    ci = ""
    if p.get("ci"):
        lo, hi = -0.02, 0.15
        X = lambda v: (v - lo) / (hi - lo) * 100
        ci = f"""<div class="ci glass" role="img" aria-label="Illustrative pilot: estimated gain from recalibrating +0.0784 net benefit per person, 95 percent range +0.0326 to +0.1251, above the 0.02 tolerance">
<p class="code" style="color:var(--amber)">Illustrative pilot · not field evidence</p>
<p style="margin:6px 0 0;color:var(--ink)"><b>Gain from recalibrating</b> · estimate <b>+0.0784</b> net benefit per person</p>
<div class="bar"><span class="axis"></span><span class="zero" style="left:{X(0):.1f}%"></span><span class="tol" style="left:{X(0.02):.1f}%"></span><span class="range" style="left:{X(0.0326):.1f}%;width:{X(0.1251) - X(0.0326):.1f}%"></span><span class="est" style="left:{X(0.0784):.1f}%"></span></div>
<div class="lbls"><span>0</span><span>tolerance 0.02</span><span>+0.0326 … +0.1251</span></div>
<p class="note" style="margin:12px 0 0">One supplied simulated pilot: the full confidence range is above zero, supporting recalibration. Open the tool to audit your own pilot, examine the checks, and export a report. Randomized treatment and a representative pilot are required.</p></div>"""
    finds = ""
    if p.get("findings"):
        finds = '<ul class="findings">' + "".join(f"<li>{f}</li>" for f in p["findings"]) + "</ul>"
    res = '<div class="reslinks">' + "".join(f'<a href="{u}"{a_attrs(u)}><span>{k}</span>{t}</a>' for k, t, u in p["res"]) + "</div>"
    tags = f'<p class="tags">{p["tags"]}</p>' if p.get("tags") else ""
    ctat, ctau = p["cta"]
    return f"""<article class="project reveal" id="{p['id']}" style="--accent:{p['accent']}">
<div class="art" aria-hidden="true"><img src="assets/img/art/{p['art']}.webp" alt="" loading="lazy" width="1600" height="900"></div>
<div class="inner">
<div class="tag-row"><span class="code">{n:02d} / {p['name'].upper()}</span>{badge}</div>
<p class="eyebrow" style="margin-top:14px">{p['label']}</p>
<h3>{p['title']}</h3>
<p class="lead">{p['lead']}</p>
{kicker}{stats}{ci}
<div class="links"><a class="btn" href="{ctau}"{a_attrs(ctau)}>{ctat} <span aria-hidden="true">→</span></a></div>
{res}{finds}{tags}
</div></article>
"""


def index_page():
    idx = "".join(f'<a href="#{p["id"]}"><span class="k">{p["idx"]}</span><span class="t">{p["name"]}</span></a>' for p in PROJECTS)
    projects = "".join(project_html(p, i + 1) for i, p in enumerate(PROJECTS))
    orbits = ""
    return head("Sahil — Data Science & Research", "Sahil's work in statistics, machine learning and data science, with applications in sustainability, climate, energy, health and the SDGs.") + nav() + f"""
<main id="main">
<section class="hero" id="top">
<div class="floor" aria-hidden="true"></div><div class="horizon" aria-hidden="true"></div><div class="scan" aria-hidden="true"></div>
<span class="corner c1" aria-hidden="true"></span><span class="corner c2" aria-hidden="true"></span><span class="corner c3" aria-hidden="true"></span><span class="corner c4" aria-hidden="true"></span>
<span class="code hud-l" aria-hidden="true">SJ/00 — RESEARCH CONSOLE</span><span class="code hud-r" aria-hidden="true">39.33° N · 76.62° W</span>
<div class="hero-inner">
<div class="lab-mark"><canvas class="orbit-canvas" aria-hidden="true"></canvas><div class="logo-glow"><div class="logo-chrome" role="img" aria-label="Sahil Lab"></div></div></div>
<p class="eyebrow" style="color:var(--ink-2)">Johns Hopkins University · MSE · 2026–28</p>
<h1>Data science.<br>Evidence before conclusions.<span class="cursor" aria-hidden="true"></span></h1>
<p class="sub">Statistical and machine-learning research on sustainability and development. B.S. (Honours with Research), TISS Mumbai.</p>
<a class="btn pulse" href="#research">Explore research <span aria-hidden="true">→</span></a>
</div>
<a class="scroll-cue" href="#education">SCROLL ↓</a>
</section>

<section class="block" id="education"><div class="wrap">
{hud("01 / EDUCATION", "Training", "Education")}
<div class="edu">
<article class="glass reveal">
<span class="status">CURRENT STUDENT</span>
<h3>Johns Hopkins University</h3>
<p class="deg">MSE, Data Science</p>
<p class="meta"><span>Baltimore, Maryland</span><span>2026–2028</span></p>
<p>Graduate study in applied statistics, data analysis and artificial intelligence. August 2026 – May 2028. Admitted with a Departmental Scholarship.</p>
<p>Current coursework includes Applied Statistics &amp; Data Analysis I, Introduction to Data Science and Artificial Intelligence. This builds on my undergraduate training by developing greater depth in statistical reasoning, computational methods and the evaluation of data-driven models.</p>
</article>
<article class="glass reveal">
<span class="status" style="color:var(--amber)">COMPLETED AUGUST 2026</span><span class="grade">Grade A+</span>
<h3>Tata Institute of Social Sciences</h3>
<p class="deg">B.S. (Honours with Research), Analytics &amp; Sustainability Studies</p>
<p class="meta"><span>Mumbai, India</span><span>2022–2026</span></p>
<p>Eight semesters across statistics, programming, machine learning, GIS and environmental science, with two supervised field immersions and a research dissertation.</p>
<p><span class="code" style="color:var(--amber)">Honours thesis</span><br><span style="color:var(--ink)">Planetary Boundary Transgressions and Divergent Socio-Economic Pathways: A Cross-National Quantitative Analysis</span><br><span class="note">Supervisor: Dr. Kamal Kumar Murari · Summer internship: Good Business Lab</span></p>
<p class="note">Courses graded 9.0/10 and above · 13 courses</p>
</article>
</div></div></section>

<section class="block" id="research"><div class="wrap">
{hud("02 / RESEARCH &amp; PROJECTS", "Newest first", "Research &amp; Projects", "Research and open tools, newest first. Explore the question, evidence and results.")}
<nav class="index reveal" aria-label="Projects">{idx}</nav>
{projects}
</div></section>

<section class="block" id="commentary"><div class="wrap">
{hud("03 / COMMENTARY", "Theory", "Commentary", "Prediction, lived experience and whose goals a model serves.")}
<article class="paper glass reveal">
<p class="eyebrow" style="color:var(--blue)">Theory paper · October 2026</p>
<h3>Knowing People Without Making Them</h3>
<p class="subtitle">A Theory of Closure, Experience, and Person-Aligned Prediction in Complex Social Systems</p>
<p>Does a model understand people — or make them easier to predict? This paper distinguishes predictability discovered through information from predictability manufactured by shaping someone’s environment. It connects that distinction to lived experience, the exclusion of data-poor groups, and prediction directed toward a person’s own reflectively endorsed goals.</p>
<a class="btn" href="{L}/__l5e/assets-v1/91c1bce6-a300-4b72-b14c-f174d806d2e0/knowing_without_making-2.pdf"{EXT} style="--accent:var(--blue);border-color:var(--blue)">Read the full paper (PDF) <span aria-hidden="true">↗</span></a>
<p class="code" style="margin-top:34px">The central ideas</p>
<div class="ideas">
<div><b>World closure</b>How much uncertainty is resolved by variables a predictor controls.</div>
<div><b>The human residual</b>Experience can explain differences that demographic models leave behind.</div>
<div><b>Data capture</b>Less recorded data can mean less recognition of genuine need.</div>
<div><b>Person-aligned prediction</b>Support the person’s goals, with self-authored limits on steering.</div>
</div>
<details class="expand"><summary><span class="code" style="color:var(--teal)">Interactive evidence · S1 · S2 · S3</span><br>Explore the three simulations and supporting code<small>Closure ratchet, data capture and experience: question, setup, figure and reproducible Python</small></summary>
<div class="body">
<p>The paper makes three claims about prediction in social systems. Each simulation below is a small, controlled model built to make one claim visible: accuracy can be manufactured, missing data can hide need, and experience explains what demographics miss.</p>
<p class="note">Illustrative simulations under stated assumptions, not empirical evidence about real people. The paper sets out nine falsifiable hypotheses for future testing.</p>
<div class="sims">
{sim("S1 / Closure ratchet", "When accuracy is manufactured", "Can a recommender look more accurate simply by changing what people want?", "A simulated user interacts with three recommendation policies over repeated rounds: engagement-greedy, a neutral mirror, and goal-targeted (aims at the person’s stated goal).", "Predictability and entropy removed rise sharply under the greedy policy as preferences narrow; the mirror leaves preferences unchanged; goal-targeted moves choices toward the goal without the same collapse in diversity.", "High accuracy is not proof of understanding — it can come from shaping people. Evaluation should ask how predictability was achieved.", L + "/__l5e/assets-v1/79c27d50-3516-43bd-8730-7823bee5fe2e/s1_closure_ratchet.pdf")}
{sim("S2 / Data capture", "Equal need, unequal visibility", "Do people with fewer records get overlooked even when their need is the same?", "Groups with identical true need differ only in how many records exist about them. A standard shrinkage estimator pools sparse groups toward the average, and an eligibility cutoff decides who is served.", "As record count falls (log scale), estimated need is pulled below the cutoff and the probability of being served drops. A Monte Carlo check matches the closed-form result.", "Data-poor groups can be systematically under-served by “neutral” statistics — less data becomes less recognition.", L + "/__l5e/assets-v1/8f2d70aa-546a-48fa-a6b6-c39333e8ab92/s2_data_capture.pdf")}
{sim("S3 / Experience", "What demographics leave out", "How much of behaviour is left unexplained by income and group membership alone?", "A synthetic population in which risk-taking depends on demographics and on each person’s accumulated experience history.", "Adding experience raises in-sample explained variance from 0.27 to 0.54. People with the same income and group still differ, and larger experiential distance goes with larger differences in risk-taking.", "Models built only on demographic categories miss a “human residual”; lived experience is a measurable source of difference.", L + "/__l5e/assets-v1/6da600b2-d7fe-4460-8a2f-fbca7f1e2af4/s3_experience.pdf")}
<div class="sim"><span class="code" style="color:var(--teal)">Reproducibility</span><h4>Simulation source</h4><p>One Python script (NumPy, SciPy, Matplotlib; random seed 2026) regenerates all three figures and a results file, so every number above can be reproduced.</p><a class="btn" href="{L}/commentary/simulations.py"{EXT}>Download Python code <span aria-hidden="true">↓</span></a></div>
</div></div></details>
</article>
</div></section>

<section class="block" id="about"><div class="wrap">
{hud("04 / ABOUT ME", "Profile", "About me", "Experience, fieldwork, skills and projects.")}
<div class="about-grid">
<article class="glass reveal"><span class="code">Current position</span><h3>Research Assistant, Johns Hopkins University</h3><p class="note">Prof. Paul J. Ferraro · October 2026–present</p></article>
<article class="glass reveal"><span class="code">Internship</span><h3>Research Intern, Good Business Lab</h3><p class="note">Randomised trial on women’s participation in automotive manufacturing · 2025</p></article>
<article class="glass reveal"><span class="code">Fieldwork</span><h3>Rural Osmanabad &amp; Urban Varanasi</h3><p class="note">Two supervised field immersions at TISS</p></article>
<article class="glass reveal"><span class="code">Skills &amp; projects</span><h3>Statistics, ML and data systems</h3><p class="note">Tools, methods and academic projects</p></article>
</div>
<p style="margin-top:28px"><a class="btn" href="about.html">Read more about me <span aria-hidden="true">→</span></a></p>
</div></section>

<section class="block" id="credits" style="padding-top:20px"><div class="wrap">
<p class="eyebrow">Data credits</p>
<h2 style="font-size:clamp(30px,4vw,44px)">Open data &amp; references</h2>
<p style="max-width:680px;margin-top:14px">This research stands on openly published data. Thank you to the institutions that collect and share it.</p>
<details class="expand"><summary>Show all data sources &amp; references<small>9 projects</small></summary><div class="body">
<div class="credits-grid">
{credits()}
</div>
<p class="note" style="margin-top:20px">Source dates, methods and software credits for Charm City Pulse are listed in the tool’s References view. Section artwork on this site is computer-rendered illustration, not study results or real imagery.</p>
</div></details>
</div></section>

<section class="contact" id="contact"><div class="wrap">
<p class="eyebrow">Let’s connect</p>
<h2>Good questions deserve<br>careful data.</h2>
<p>I'm looking for research and data science work in environment, health, development and public policy, where the questions are real and the data needs care.</p>
<div class="row"><a class="btn pulse" href="mailto:{EMAIL}">{EMAIL} <span aria-hidden="true">↗</span></a><a class="btn" href="{LINKEDIN}"{EXT}>LinkedIn ↗</a><a class="btn" href="{GH}"{EXT}>GitHub ↗</a><a class="btn" href="{CV}">CV (PDF) ↗</a></div>
<p class="code" style="margin-top:28px">Baltimore, Maryland</p>
</div></section>
</main>
""" + foot()


def sim(code, title, q, setup, shows, why, pdf):
    return f"""<div class="sim"><span class="code" style="color:var(--teal)">{code}</span><h4>{title}</h4><dl>
<dt>QUESTION</dt><dd>{q}</dd><dt>SETUP</dt><dd>{setup}</dd><dt>WHAT THE FIGURE SHOWS</dt><dd>{shows}</dd><dt>WHY IT MATTERS</dt><dd>{why}</dd></dl>
<p style="margin:14px 0 0"><a href="{pdf}"{EXT}>Open original figure (PDF) ↗</a></p></div>"""


CREDITS = [
    ("Charm City Pulse", ["U.S. Census Bureau · ACS survey estimates", "CDC PLACES · Model-based health estimates", "NOAA / National Weather Service · Official alerts", "EPA AirNow · Air-quality monitors", "Open-Meteo · Weather and modeled air quality", "USGS · Stream gauges", "FEMA · Flood hazard zones", "Open Baltimore · Public amenities and centers", "OpenStreetMap · Places and map data"]),
    ("PolicyAudit", ["NSW job-training demonstration data (Lalonde 1986; Dehejia–Wahba sample)", "Double/debiased machine learning (Chernozhukov et al., 2018)"]),
    ("Do New Street Trees Cool Baltimore?", ["Baltimore street-tree inventory, Open Baltimore", "USGS Landsat 5/7/8/9 surface temperature", "TreeBaltimore planting records"]),
    ("Baltimore Heat Atlas", ["USGS Landsat Collection 2", "NASA MODIS", "Microsoft Planetary Computer", "ESA WorldCover 2021", "CDC PLACES, CDC/ATSDR SVI & Heat and Health Index", "U.S. Census Bureau ACS & TIGER", "Mapping Inequality, University of Richmond", "Baltimore City Health Department", "BNIA Community Statistical Areas", "NOAA RCC-ACIS & National Weather Service"]),
    ("Social shortfall & climate overshoot", ["World Bank World Development Indicators", "Our World in Data CO₂ accounts", "Maddison Project Database (PPP income)"]),
    ("Global Sustainability Explorer", ["UN SDG Global Database", "World Bank open data", "Our World in Data"]),
    ("Planetary boundaries & development", ["World Bank WDI", "FAOSTAT", "WHO Global Health Observatory", "ILOSTAT", "UNDP Human Development Reports"]),
    ("Energy transition", ["World Bank", "UN SDG 7.2.1 database", "Our World in Data", "Ember", "Energy Institute Statistical Review"]),
    ("SDG Explorer India", ["UN SDG Global Database", "MoSPI, Government of India", "NITI Aayog SDG India Index", "NFHS, IIPS Mumbai"]),
]


def credits():
    return "".join(f"<section><h4>{t}</h4><ul>" + "".join(f"<li>{x}</li>" for x in xs) + "</ul></section>" for t, xs in CREDITS)


SDG = ["#e5243b", "#dda63a", "#4c9f38", "#c5192d", "#ff3a21", "#26bde2", "#fcc30b", "#a21942", "#fd6925", "#dd1367", "#fd9d24", "#bf8b2e", "#3f7e44", "#0a97d9", "#56c02b", "#00689d", "#19486a"]


def about_page():
    sub = "".join(f'<a href="#{i}">{t}</a>' for t, i in [("Research experience", "research-experience"), ("Internship", "internship"), ("Skills", "skills"), ("Fieldwork", "fieldwork"), ("Recommendations", "recommendations"), ("Academic projects", "academic-projects")])
    sdg = "".join(f'<span style="background:{c}">{i + 1}</span>' for i, c in enumerate(SDG))
    return head("About Sahil — Experience, fieldwork and skills", "Research experience, internship, fieldwork, skills and recommendations.") + nav(home=False) + f"""
<main id="main"><div class="wrap">
<section class="page-hero"><p class="eyebrow">About me</p><h1>From fieldwork<br>to models.</h1>
<p style="max-width:700px;font-size:19px">Research experience, an internship on a randomised trial, two field immersions and the tools I use to get from a real question to careful evidence.</p>
<nav class="subnav" aria-label="About sections">{sub}</nav></section>

<section class="block" id="research-experience">{hud("01 / RESEARCH EXPERIENCE", "Current", "Research experience")}
<article class="glass reveal" style="padding:32px"><h3 style="font-size:28px">Research Assistant, Johns Hopkins University</h3>
<p class="code" style="margin:10px 0 4px">Baltimore, MD · October 2026–present</p><p class="note">Supervisor: Prof. Paul J. Ferraro</p>
<ul><li>Reproducing the analysis of “China’s solar expansion policy reduces bird diversity” (<i>Science</i>) using the authors’ public data and code.</li><li>Extending the evaluation with alternative estimators and sensitivity analyses for unobserved confounding.</li></ul></article></section>

<section class="block" id="internship">{hud("02 / INTERNSHIP", "Randomised trial", "Internship")}
<article class="glass reveal" style="padding:32px"><h3 style="font-size:28px">Research Intern, Good Business Lab</h3>
<p class="code" style="margin:10px 0 16px">New Delhi, India · 2 June – 1 August 2025</p>
<p>Worked on a randomised trial, run with the Automotive Component Manufacturers Association, on increasing women's participation in automotive manufacturing.</p>
<ul><li>Built structured survey instruments in SurveyCTO with logic checks, tested them on tablets, and validated incoming data.</li><li>Trained enumerators and supported sampling and a literature review.</li><li>Built an automated CV-generation system.</li></ul>
<p>The work combined research preparation with practical field operations: survey logic had to work on tablets, enumerators needed consistent instructions, and incoming responses required validation. These responsibilities helped connect a study’s design to the quality of the evidence it can eventually produce.</p>
<p class="note"><i>I contributed to the design, instruments and data collection for an ongoing trial. I did not analyse or report its results.</i></p></article></section>

<section class="block" id="skills">{hud("03 / SKILLS &amp; APPROACH", "Approach", "From fieldwork to models")}
<div class="two-col reveal"><div>
<p>I trained in analytics and sustainability at the Tata Institute of Social Sciences. That meant combining quantitative methods with fieldwork in rural Maharashtra and urban Uttar Pradesh, and with a randomised evaluation at Good Business Lab. At Johns Hopkins I’m building depth in machine learning, statistical modelling and data systems.</p>
<p>My work tends to follow the same pattern: start from a real question, get the data right, choose methods that fit, and be honest about what the results do and don't show. That means held-out validation for predictive models, survey weights for survey data, and calling associations associations rather than causes.</p>
<h3 style="font-size:22px;margin:26px 0 8px">Currently learning</h3><p class="code" style="color:var(--teal)">Statistics · Machine Learning · Research Methods · Data Systems</p>
<p>I am developing these areas together: statistical methods help frame uncertainty, machine learning helps test predictive patterns, and research methods help determine whether the evidence answers the original question. Data systems support the preparation and organisation that each of those steps depends on.</p>
</div><div class="glass" style="padding:28px">
<h3 style="font-size:22px;margin-bottom:10px">Tools</h3><p class="code" style="text-transform:none;letter-spacing:.02em;line-height:1.8">Python (pandas, NumPy, scikit-learn, SciPy, matplotlib) · R · SQL · STATA · SPSS · MATLAB · Power BI · Tableau · Excel · QGIS / ArcGIS · SurveyCTO · Google Apps Script · Git, pytest, GitHub Actions</p>
<p>I use programming and statistical tools to clean, validate and analyse data; visualisation tools to communicate findings; and SurveyCTO to turn survey instruments into usable field forms. My research and field experience bring these tools together, from preparing evidence to interpreting and communicating results.</p>
<h3 style="font-size:22px;margin:22px 0 10px">Methods</h3><p class="code" style="text-transform:none;letter-spacing:.02em;line-height:1.8">Survey design and primary data collection · data validation · randomised evaluation (RCT) · regression · classification · time-series forecasting · k-means clustering · PCA and factor analysis · composite indices · survey-weighted estimation · linear and integer programming · GIS and mapping · data visualisation</p>
</div></div></section>

<section class="block" id="fieldwork">{hud("04 / FIELDWORK", "First-hand perspective", "Fieldwork.", "Two supervised field immersions at TISS: farming households and urban markets.")}
{field("Rural / August–September 2023", "Osmanabad, Maharashtra", "Climate, agriculture and household sustainability",
       "How agricultural communities understand climate conditions, farming practices and adaptation, alongside the socioeconomic realities of farming households.",
       "I designed survey instruments and collected primary socioeconomic data directly from farming households. Field observations documented agronomy, household sustainability and community experiences of climate adaptation. The work brought household economics, agricultural practices and adaptation strategies into the same enquiry, rather than treating environmental conditions as separate from livelihoods.",
       "This work connected environmental questions to the household scale: a survey response needs to be read alongside the farming conditions and community context in which it was collected. It reinforced the importance of defining questions clearly, documenting how responses are obtained and preserving context when organising primary data for analysis.",
       "Survey design determines what can be measured later. This immersion grounded my interest in sustainability in first-hand data collection, while reminding me that numerical summaries cannot replace the experience and circumstances behind each observation.",
       "Supervised field research and primary data collection; not a causal evaluation of adaptation outcomes.")}
{field("Urban / 2024", "Varanasi, Uttar Pradesh", "Market systems and informal economies",
       "How goods and work connect across dense urban markets: commodity flows, supply chains, informal labour structures and the relationships between wholesalers and retailers.",
       "I conducted on-site field research, documented market activity, and collected, organised and analysed observations to identify linkage patterns across the urban environment. The emphasis was on how wholesale and retail activity relate to commodity movement and informal work, so the unit of interest was the linkage between activities as well as the individual market participant.",
       "The market became a connected system rather than a list of individual shops. Following goods between wholesale and retail made relationships, labour and local context central to interpreting the observations. Organising field notes into linkage patterns made it possible to move from individual observations towards a structured account of the market system, without claiming that the observations represented the entire city.",
       "This study strengthened the step that comes before modelling: deciding what a record represents, how activities connect and which context must be retained. Those choices shape how relationships can be described in a dataset and how cautiously the resulting patterns should be interpreted.",
       "An observational study of market linkages; it does not estimate the size of the informal economy.")}
</section>

<section class="block" id="recommendations">{hud("05 / RECOMMENDATIONS", "In their words", "Recommendations")}
<div class="quotes">
<blockquote class="glass reveal"><p>Throughout the programme, Mr. Sahil demonstrated sincerity, diligence, and professionalism. We are confident in his ability to contribute effectively in academic and professional settings.</p><cite>Prof. Bino Paul, Chairperson, Labour Market Research Facility, and Prof. Zubin Mulla, Dean, School of Management and Labour Studies — Tata Institute of Social Sciences, 2 August 2026</cite></blockquote>
<blockquote class="glass reveal"><p>He demonstrated courage by taking initiative and being result-oriented, particularly in data and programming tasks.</p><cite>Dia Bangera, Director – Operations, Good Business Lab Foundation, 8 August 2025</cite></blockquote>
<blockquote class="glass reveal"><p>Sahil was an intelligent and inquisitive intern, and his contributions proved valuable across various research-related tasks and during occasional fieldwork.</p><cite>Internship experience letter, Good Business Lab Foundation · 8 August 2025</cite></blockquote>
<blockquote class="glass reveal"><p>He displayed effective collaboration through seamless coordination with Research and Field Teams.</p><cite>Internship experience letter, Good Business Lab Foundation</cite></blockquote>
</div></section>

<section class="block reveal"><div class="two-col" style="align-items:center"><div>
<h2 style="font-size:clamp(36px,5vw,60px);font-weight:800">Seventeen goals, four years</h2>
<p style="margin-top:16px">My degree ran across sustainability, development, climate and social research — which in practice meant touching most of the UN Sustainable Development Goals at some point: climate action in coursework and thesis, decent work and gender equality at Good Business Lab, life on land and clean energy in the pressure index, zero hunger and gender equality in rural fieldwork.</p>
</div><div><div class="sdg" role="img" aria-label="The 17 UN Sustainable Development Goals">{sdg}</div><p class="note" style="margin-top:10px">The 17 UN Sustainable Development Goals, in their official numbering and colours.</p></div></div></section>

<section class="block" id="academic-projects">{hud("06 / ACADEMIC PROJECTS", "Coursework", "Academic projects", "Coursework projects collected in one repository.")}
<a class="btn" href="{GH}/Academic-Projects"{EXT}>Explore my academic projects on GitHub <span aria-hidden="true">↗</span></a>
<a class="btn" href="{CV}" style="margin-left:8px">CV (PDF) ↗</a></section>
</div></main>
""" + foot()


def field(when, place, theme, inv, how, brought, conn, caveat):
    return f"""<article class="field reveal"><div><p class="eyebrow">{when}</p><h3>{place}</h3><p>{theme}</p></div><div>
<h4>What I investigated</h4><p>{inv}</p><h4>How I worked</h4><p>{how}</p><h4>What this brought to my research</h4><p>{brought}</p><h4>Connection to quantitative work</h4><p>{conn}</p>
<p class="note glass" style="padding:12px 16px">{caveat}</p></div></article>"""


def trees_page():
    b = "../"
    rows = [("Main specification", "−0.026 [−0.047, −0.005]"), ("All site types × year (strictest)", "−0.027 [−0.048, −0.006]"), ("Unweighted", "−0.028 [−0.048, −0.007]"),
            ("Clustered by 55 CSAs", "−0.026 [−0.047, −0.006]"), ("Cell-years with ≥ 3 clear scenes", "−0.026 [−0.047, −0.005]"), ("Excluding cells with park trees", "−0.023 [−0.045, −0.002]"),
            ("Year FE only (no neighborhood × year)", "−0.096 [−0.131, −0.060]"), ("Long difference, sensitivity-adjusted for a confounder 3× as strong as mature-tree density", "−0.024 [−0.038, −0.009]")]
    table = "".join(f"<tr><td>{a}</td><td>{c}</td></tr>" for a, c in rows)
    return head("Do New Street Trees Cool Baltimore? | Sahil", "A within-neighborhood event study of Baltimore's street-tree plantings and summer surface temperature, 2006–2025.", b) + nav(b, home=False) + f"""
<main id="main"><div class="wrap">
<section class="page-hero"><p class="eyebrow">Working paper · October 2026</p><h1>Do new street trees<br>cool Baltimore?</h1>
<p style="max-width:760px;font-size:19px">A within-neighborhood event study of Baltimore's street-tree plantings and summer surface temperature, 2006–2025. Sahil, Johns Hopkins University.</p>
<div class="links" style="display:flex;gap:12px;flex-wrap:wrap;margin-top:24px"><a class="btn" href="{b}papers/baltimore-street-tree-paper.pdf">Read the paper (PDF) ↗</a><a class="btn" href="{GH}/baltimore-tree-cooling"{EXT}>Code &amp; data on GitHub ↗</a><a class="btn" href="{GH}/baltimore-tree-cooling/blob/main/docs/VERIFICATION.md"{EXT}>Reproducibility report ↗</a></div></section>
<div class="prose">
<div class="callout glass"><span class="code">Headline result</span><b class="big">−0.026 °C</b>
<p>Each young street tree (trunk ≤ 1.5 in in the 2017–18 city inventory, so planted roughly 2014–17) lowered the summer surface temperature of its 90 m surroundings by <b>0.026 °C by 2022–25</b> relative to 2006–09 (95% CI 0.005–0.047 °C), with <b>no detectable change before planting</b> (pre-trend test p = 0.63). The cooling appears only after 2018 and grows as the trees mature. A 90 m cell with five new saplings (an ordinary planted block face) is about 0.13 °C cooler.</p></div>
<p>That size is what simple physics predicts: a young crown shades roughly 0.2% of a 90 m cell, and if shade is roughly 10–15 °C cooler than sunlit pavement (a rough assumption, not a measurement), that gives 0.02–0.03 °C per tree.</p>
<figure><img src="{b}assets/img/fig/fig1_event_study_cohorts.webp" alt="Event-study estimates of surface temperature change per tree by trunk-size cohort and period" loading="lazy"><figcaption>Figure 1. Event study by trunk-size cohort: young trees show no pre-planting trend and growing cooling after 2018.</figcaption></figure>
<h2>Why a naive comparison fails</h2>
<p>Neighborhoods that got more trees in 2013–20 were already cooling in 2009–12, before those plantings (pre-trend p &lt; 0.001). That selection problem is what this design exists to solve.</p>
<figure><img src="{b}assets/img/fig/fig2_design_comparison.webp" alt="Comparison of the naive neighborhood design with the within-neighborhood design" loading="lazy"><figcaption>Figure 2. Naive whole-neighborhood comparison versus the within-neighborhood design.</figcaption></figure>
<h2>Design</h2>
<p>Baltimore's Forestry Division surveyed every public street tree and every empty planting site in 2017–18 (193,009 records). Trunk size dates the young trees. Empty sites the city judged plantable are the comparison group: same streetscape screen, no tree yet. Landsat 5/7/8/9 summer scenes (111 usable, 2006–2025) give each 90 m cell's surface temperature relative to that day's citywide median. The regression has cell fixed effects and neighborhood × year fixed effects, so it compares blocks within the same neighborhood in the same year. It interacts the count of trees in each trunk-size cohort with year, controlling for vacant sites, mature trees and stumps × year. Standard errors are clustered by neighborhood (277).</p>
<h2>Robustness</h2>
<p class="note">2022–25 effect per young tree, °C, 95% CI</p>
<div class="table-scroll"><table class="data"><thead><tr><th>Check</th><th>Estimate</th></tr></thead><tbody>{table}</tbody></table></div>
<p>The year-FE-only estimate is 3–4 times larger, which shows how much neighborhood-wide trends would inflate a naive estimate.</p>
<h2>Known problems</h2>
<ul>
<li><b>Planting dates are inferred from trunk size.</b> The city's public layer has no usable planting date. Exact dates would sharpen the design.</li>
<li><b>The placebo failed.</b> “Not suitable” planting sites also cool (−0.09 °C per site). They cluster in dense rowhouse blocks that have cooled since 2010, plausibly from vacant-house demolitions. The young-tree estimate does not move when those trends are controlled, but demolition data should be added directly.</li>
<li><b>Surface temperature, not air temperature or health.</b> Landsat measures surface (skin) temperature on clear summer late mornings.</li>
<li><b>Survivorship.</b> Only trees alive in 2017–18 are counted, which biases toward successful plantings.</li>
</ul>
<h2>Reproducibility</h2>
<p>Raw data are fixed and checksummed; every quoted number is recomputed and checked by a verification script; and a GitHub Actions workflow rebuilds everything from scratch on a clean machine on every push.</p>
<p><a href="{GH}/baltimore-tree-cooling/actions/workflows/reproduce.yml"{EXT}>Latest reproduce run ↗</a></p>
<h2>Related work</h2>
<ul><li><a href="{IO}/baltimore-heat-atlas/"{EXT}>Baltimore Heat Atlas</a>: the tract-level heat vulnerability index this study grew out of.</li>
<li><a href="{IO}/charm-city-pulse/"{EXT}>Charm City Pulse</a>: a public app that shows residents their block's tree shade and points them to TreeBaltimore's free street trees.</li></ul>
<p style="margin-top:40px"><a class="btn" href="{b}index.html#s-trees">← Back to research</a></p>
</div></div></main>
""" + foot(b)




def writing_page():
    def item(kind, title, sub, href=None, label="Read paper"):
        link = f'<a class="btn" href="{href}"{a_attrs(href)}>{label} <span aria-hidden="true">↗</span></a>' if href else '<p class="note">Original thesis PDF not yet available</p>'
        return f'<article class="glass reveal" style="padding:26px"><span class="code">{kind}</span><h3 style="font-size:24px;margin:8px 0 8px">{title}</h3><p>{sub}</p>{link}</article>'
    com = item("Theory paper · October 2026", "Knowing People Without Making Them", "A Theory of Closure, Experience, and Person-Aligned Prediction in Complex Social Systems.", L + "/__l5e/assets-v1/91c1bce6-a300-4b72-b14c-f174d806d2e0/knowing_without_making-2.pdf")
    papers = "".join([
        item("Working paper · October 2026", "Do New Street Trees Cool Baltimore?", "Within-neighborhood evidence from Baltimore’s street-tree program, 2006–2025.", "papers/baltimore-street-tree-paper.pdf"),
        item("Baltimore Heat Atlas", "Where heat meets vulnerability", "Summer surface heat, health and social conditions across Baltimore City.", "papers/baltimore-heat-vulnerability.pdf"),
        item("Climate &amp; development", "Social shortfall, climate overshoot and the falling carbon cost of development", "A study of social development and climate pressure.", "papers/social-shortfall-climate-overshoot.pdf"),
        item("Undergraduate thesis · TISS", "Planetary Boundary Transgressions and Divergent Socio-Economic Pathways", "A world-level study of planetary pressure and development, 1990–2023."),
    ])
    reports = "".join([
        item("Technical report · November 2026", "Neural Network Lab", "An open, browser-based training console and interactive curriculum: the lab’s learning engine, curriculum and reproducible checks.", "papers/neural-network-lab-technical-report.pdf", "Read report"),
        item("Technical report", "Energy Transition and Development", "Renewable energy trends, income comparisons and the question of convergence.", "papers/energy-transition-report.pdf", "Read report"),
        item("Method &amp; validation", "PolicyAudit", "The manual for auditing treatment-targeting models using randomized pilot data.", L + "/__l5e/assets-v1/c99d0db8-79ed-42fa-8bf9-73922aa30bda/policyaudit_manual.pdf", "Read manual"),
    ])
    grid = 'style="display:grid;grid-template-columns:repeat(auto-fit,minmax(300px,1fr));gap:16px"'
    return head("Writing — Sahil", "Research papers, commentary and technical reports by Sahil.") + nav(home=False) + f"""
<main id="main"><div class="wrap">
<section class="page-hero"><p class="eyebrow">Papers · Commentary · Reports</p><h1>Writing</h1>
<p style="max-width:700px;font-size:19px">Research papers, ideas and methods on people, development and the environment.</p></section>
<section class="block" style="padding-top:20px">{hud("01 / COMMENTARY", "Theory", "Commentary")}<div {grid}>{com}</div></section>
<section class="block">{hud("02 / RESEARCH PAPERS", "Working papers", "Research papers")}<div {grid}>{papers}</div></section>
<section class="block">{hud("03 / REPORTS &amp; METHODS", "Technical", "Reports &amp; methods")}<div {grid}>{reports}</div></section>
</div></main>
""" + foot()


open(os.path.join(ROOT, "writing.html"), "w").write(writing_page())
open(os.path.join(ROOT, "index.html"), "w").write(index_page())
open(os.path.join(ROOT, "about.html"), "w").write(about_page())
open(os.path.join(ROOT, "research", "baltimore-street-trees.html"), "w").write(trees_page())
print("built")
