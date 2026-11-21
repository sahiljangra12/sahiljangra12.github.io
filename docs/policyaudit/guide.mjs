import { fieldHelp, decisionHelp } from './guide-content.mjs';

function block(html, className = 'audit-help') {
  const el = document.createElement('div');
  el.className = className;
  el.innerHTML = html;
  return el;
}
function addOnce(host, key, html, position = 'append') {
  if (!host || host.querySelector(`[data-guide="${key}"]`)) return;
  const el = block(html); el.dataset.guide = key;
  if (position === 'prepend') host.prepend(el); else host.append(el);
}
function enhance() {
  const audit = document.querySelector('#audit');
  if (!audit) return;
  const steps = audit.querySelector('ol');
  if (steps && !document.querySelector('#audit-roadmap')) {
    const intro = block(`<div class="guide-intro"><span class="guide-kicker">Before you start</span><h3>What is this tool, in plain words?</h3><p>Imagine a hospital has a computer model that predicts <em>which patients benefit most</em> from an expensive treatment, so only those patients get it. The model was built on last year’s patients. Now the hospital moves to a new city — different people, maybe different results. <strong>Should the hospital keep trusting the old model, adjust it, or wait for more evidence?</strong></p><p>PolicyAudit answers exactly that question. You run a small <strong>randomized pilot</strong> in the new setting — some people randomly get the treatment, some don’t — and upload the results here. The tool then tells you one of three things:</p><ul class="guide-outcomes"><li><strong>Keep</strong> — your current model’s decisions still look fine.</li><li><strong>Recalibrate</strong> — a small, evidence-based adjustment to the model would clearly help.</li><li><strong>Collect more</strong> — the pilot is too small to decide yet; here is roughly how much more data you need.</li></ul><p><strong>You also get:</strong> how large the improvement is (with honest uncertainty), safety checks, a shareable report, and a file of treatment recommendations you can download.</p><p class="guide-note">Everything runs in this browser tab — your data is never uploaded anywhere.</p></div><nav class="guide-steps" aria-label="Audit steps"><a href="#guide-load"><span>01</span>Load data</a><a href="#guide-map"><span>02</span>Check columns</a><a href="#guide-rule"><span>03</span>Set the rule</a><a href="#guide-results"><span>04</span>Read & export</a></nav><details class="guide-readiness"><summary>When should I use this — and what CSV do I need?</summary><p class="guide-subhead">When this tool is the right choice</p><ul class="guide-list"><li>You already have a model (or rule) that decides <strong>who should get a treatment</strong> — a medicine, a training programme, a subsidy, a marketing offer.</li><li>You are about to use it in a <strong>new setting</strong> — a new city, hospital, school district, or time period — and you are not sure it still works there.</li><li>You can run a <strong>randomized pilot</strong> in that new setting: some people get the treatment by chance, some don’t, and you measure what happens to each.</li></ul><p class="guide-subhead">When it is <em>not</em> the right choice</p><ul class="guide-list"><li>Your data is <strong>observational</strong> — doctors, teachers or the model itself chose who got treated. The tool’s math relies on random assignment.</li><li>You have <strong>no measured outcomes</strong> yet, or no model predictions to check.</li><li>You want to know whether treatment is right for <strong>one specific person</strong> — the tool judges average policy performance, not individuals.</li></ul><p class="guide-subhead">The CSV file, exactly</p><p>A plain comma-separated <strong>.csv</strong> file (Excel → “Save as CSV” works). One row per person, column names in the first row. Numbers as plain digits (e.g. <code>0.42</code>, not <code>42%</code>). Leave missing cells empty — never fill them with zero. A few hundred to a few thousand rows is the intended size.</p><div class="guide-table"><table><thead><tr><th>Column</th><th>Type</th><th>What belongs here</th></tr></thead><tbody><tr><td>treatment</td><td>0 or 1</td><td>What actually happened: 1 = treated, 0 = not treated. Nothing else (no “yes/no”, no 2).</td></tr><tr><td>outcome</td><td>number</td><td>The result measured <em>after</em> the pilot — e.g. recovered (1/0), test points gained, days in hospital.</td></tr><tr><td>source_effect</td><td>number</td><td>Your model’s predicted <em>extra</em> benefit from treatment for that person — not a risk score, not a predicted outcome.</td></tr><tr><td>age, baseline_score…</td><td>numbers</td><td>Characteristics known <em>before</em> treatment. As many as you like; you choose which to use in step 02.</td></tr><tr><td>probability <em>(optional)</em></td><td>0–1</td><td>The known assignment chance from your design. If everyone had the same chance, skip the column and enter one value in step 03.</td></tr></tbody></table></div><p>Leave out: ID numbers or names, anything measured after treatment (except the outcome), and simulated “true effect” columns. Text columns (like a city name) are ignored safely but won’t be used as characteristics.</p></details>`, 'audit-orientation');
    intro.id = 'audit-roadmap'; steps.before(intro);
    [...steps.children].forEach((el, i) => { el.id = ['guide-load', 'guide-map', 'guide-rule'][i] || ''; });
  }
  const first = document.querySelector('#guide-load');
  addOnce(first?.lastElementChild, 'load', '<p><strong>New here?</strong> Click one of the examples to see the whole thing work end to end, then check the columns in step 02 and run the audit. The examples are made-up demonstrations — they show how the tool behaves, not real-world evidence. When you load your own CSV, it is processed in this browser tab only and never uploaded.</p>');
  addOnce(first?.lastElementChild, 'realdata', `<div class="guide-realdata"><p class="guide-subhead">Try it with real data</p><p><strong>The Lalonde job-training experiment (USA, 1970s).</strong> The National Supported Work programme randomly assigned disadvantaged workers to job training, and their 1978 earnings were recorded — 445 people, a real randomized trial. The “existing model” here was fitted the way many real models are: on <em>non-randomized</em> comparison data (the PSID survey). That is exactly the situation this tool is built for.</p><p><button type="button" class="guide-realdata-btn" data-guide-load-real>Load the real example</button> <a href="/policyaudit/examples/lalonde_nsw.csv" download>Download the CSV</a> to inspect it first.</p><p>Then: in <strong>step 02</strong> map <code>treated</code> → treatment, <code>outcome</code> → outcome, <code>source_effect</code> → predicted benefit, and select the characteristics (age, education, black, hispanic, married, no_degree, earnings_1975). In <strong>step 03</strong> enter assignment probability <code>0.4157</code>, burden <code>0</code>, tolerance <code>500</code> (dollars of yearly earnings). Run the audit.</p><details><summary>What you should see — and what it teaches</summary><p>The audit answers <strong>Keep</strong>: no simple recalibration improves on the existing policy by more than $500 per person (estimated gain about −$517, plausibly between −$1,518 and +$417). The real lesson is in the checks: the model’s <strong>calibration slope is about 0.09</strong> — its predictions barely track reality. The true randomized experiment shows training raised earnings by about <strong>$1,794</strong> a year on average, but the observationally-trained model predicted only about <strong>$345</strong>. This is the famous Lalonde result: models built on non-randomized data can be badly wrong, and an audit against a randomized pilot is how you find out.</p></details></div>`);
  addOnce(document.querySelector('#guide-map')?.lastElementChild, 'features', '<details><summary>Which characteristics should I select?</summary><p>Pick the things you knew about each person <em>before</em> treatment that might affect who benefits — for example age or a baseline health score. The tool uses these to test adjusted versions of your model. Do <em>not</em> pick row IDs, assignment probabilities, the outcome, the model’s own predictions, or anything measured after treatment. The tool pre-selects its best guesses — treat them as a starting point and check them yourself.</p></details>');
  for (const [id, text] of Object.entries(fieldHelp)) {
    const input = document.getElementById(id);
    if (!input || document.getElementById(`help-${id}`)) continue;
    const p = document.createElement('p'); p.className = 'audit-field-help'; p.id = `help-${id}`; p.textContent = text;
    input.after(p); input.setAttribute('aria-describedby', [input.getAttribute('aria-describedby'), p.id].filter(Boolean).join(' '));
  }
  const probability = document.querySelector('input[aria-label="Treatment probability"]');
  addOnce(probability?.parentElement, 'probability', '<p>Enter the assignment chance from your pilot’s design. Example: a coin-flip design means 0.5 — a 50% chance for each person. That does not mean exactly half your rows will be treated; chance makes the split uneven.</p>');
  const more = document.querySelector('#guide-rule details');
  addOnce(more, 'advanced', '<p><strong>Adjust your model:</strong> gently correct your existing predictions using the pilot evidence — like nudging a thermometer that reads slightly high. <strong>Pilot-only refit:</strong> ignore the old model and fit a simple straight-line alternative from the pilot data alone. Both are <em>candidates</em> the tool tests — neither is guaranteed to be better.</p><p><strong>A lower outcome is better:</strong> tick this for outcomes like pain or days in hospital, where smaller numbers are good. Your model’s prediction must still mean “benefit of treating”, with higher = more benefit. Double-check the direction and units before running.</p>');
  const headerFigure = document.querySelector('header figure');
  addOnce(headerFigure, 'simulation', '<p><strong>These three answers are made-up illustrations.</strong> They show how the same tool can say “keep”, “recalibrate” or “collect more” depending on the evidence — they are not findings from real clinics.</p>');
  const result = audit.querySelector('article');
  const resultSlot = steps?.nextElementSibling;
  if (resultSlot) {
    resultSlot.id = 'guide-results';
    const placeholder = resultSlot.querySelector('[data-guide="pending"]');
    if (!result) addOnce(resultSlot, 'pending', '<p><strong>04 · Read & export</strong><br>Once you have loaded data, checked the columns and set the rule, run the audit. Your answer — keep, recalibrate, or collect more — will appear here, together with how confident it is, the safety checks, and files to download.</p>');
    else placeholder?.remove();
  }
  const heading = result?.querySelector('h3');
  if (result && heading) {
    let next = result.querySelector('[data-guide="decision"]');
    if (!next) { next = block(''); next.dataset.guide = 'decision'; heading.parentElement?.append(next); }
    const decision = heading.textContent.trim();
    if (next.dataset.decision !== decision) { next.dataset.decision = decision; next.replaceChildren(); const strong = document.createElement('strong'); strong.textContent = 'What this means for you'; const p = document.createElement('p'); p.textContent = decisionHelp(decision); next.append(strong, p); }
    addOnce(result, 'read-results', `<details class="guide-results-help"><summary>How to read the chart and numbers</summary><p><strong>The dot</strong> is the estimated average improvement per person if you switch to the adjusted policy, in your outcome’s units. Above zero = better than your current policy. It is only a percentage if your outcome is one.</p><p><strong>The bar</strong> shows the range the true improvement plausibly lies in. A wide bar means the pilot is small and the answer is uncertain. If the bar crosses zero, the improvement might actually be nothing. The tolerance line is the bar you set in step 03 — the gain must clearly pass it to recommend switching.</p><p><strong>Decisions changed:</strong> how many pilot participants would be treated differently under the new policy. <strong>Share treated:</strong> what fraction of people each policy would treat — not the fraction who recover.</p><p><strong>Checks:</strong> warnings about the alternatives tested or the model’s calibration. They help you judge how much to trust the answer. No warnings does not prove the policy is safe, fair, or valid for a different population.</p></details>`);
    const exportHeading = [...result.querySelectorAll('h4')].find(el => el.textContent === 'Take it with you');
    addOnce(exportHeading?.parentElement, 'exports', '<details><summary>Which download do I need?</summary><p><strong>Report:</strong> a readable summary page to open in any browser and share with colleagues or reviewers. <strong>JSON:</strong> the full results and fitted model in a structured format, for programmers and further analysis. <strong>Pilot recommendations:</strong> a spreadsheet (CSV) listing each person you uploaded and what the policy recommends for them.</p><p><strong>Score new people:</strong> upload a CSV of new people with the same characteristic columns and your model’s predicted benefit for each — no outcomes or treatment assignments needed. You get back recommended treat / don’t-treat decisions. These are policy outputs, not guarantees for any individual; review whether the new people resemble the pilot population before acting.</p></details>');
  }
}
let scheduled = false;
const observer = new MutationObserver(() => { if (scheduled) return; scheduled = true; requestAnimationFrame(() => { scheduled = false; enhance(); }); });
observer.observe(document.getElementById('root'), { childList: true, subtree: true });
document.addEventListener('click', async (ev) => {
  const btn = ev.target.closest?.('[data-guide-load-real]');
  if (!btn || btn.dataset.busy) return;
  btn.dataset.busy = '1';
  const original = btn.textContent;
  btn.textContent = 'Loading…';
  try {
    const res = await fetch('/policyaudit/examples/lalonde_nsw.csv');
    if (!res.ok) throw new Error('fetch failed');
    const blob = await res.blob();
    const file = new File([blob], 'lalonde_nsw.csv', { type: 'text/csv' });
    const input = document.querySelector('#audit input[aria-label="Pilot CSV file"]') || document.querySelector('#audit input[type="file"]');
    if (!input) throw new Error('no input');
    const dt = new DataTransfer();
    dt.items.add(file);
    input.files = dt.files;
    input.dispatchEvent(new Event('change', { bubbles: true }));
    btn.textContent = 'Loaded — continue to step 02';
  } catch {
    btn.textContent = 'Could not load — use the download link instead';
  } finally {
    setTimeout(() => { delete btn.dataset.busy; if (btn.textContent !== 'Loaded — continue to step 02') btn.textContent = original; }, 4000);
  }
});
enhance();