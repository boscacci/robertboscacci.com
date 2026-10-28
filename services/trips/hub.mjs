import { readFile, readdir, mkdir, writeFile } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { join } from 'node:path';
import { decryptPage } from '../../scripts/private-trip.mjs';

export const escapeHtml = (value) => String(value).replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
export const allowedSlug = (slug) => typeof slug === 'string' && /^[a-z0-9]+(?:-[a-z0-9]+)+$/.test(slug) && slug.length <= 100;
export function metadata(html) {
  const match = html.match(/<script id="trip-metadata" type="application\/json">([\s\S]*?)<\/script>/);
  let trip;
  try { trip = JSON.parse(match?.[1]); } catch { throw Error('Invalid trip metadata'); }
  if (!allowedSlug(trip.slug) || ['title','dates','status','summary'].some(k => typeof trip[k] !== 'string' || !trip[k] || trip[k].length > 600)) throw Error('Invalid trip metadata');
  return trip;
}
export const css = `:root{color-scheme:light;--ink:#163d39;--muted:#536862;--paper:#f6f3eb;--line:#d5ddd4;--accent:#ae542e}*{box-sizing:border-box}body{margin:0;background:var(--paper);color:var(--ink);font:17px/1.65 system-ui,sans-serif}header{background:var(--ink);color:#f9f5e9;padding:38px 0 58px}header>div,main{max-width:1100px;margin:auto;padding:0 26px}main{padding-top:30px;padding-bottom:70px}h1,h2,h3{font-family:Georgia,serif;line-height:1.12}h1{font-size:clamp(43px,7vw,75px);font-weight:400;margin:24px 0}h2{font-size:32px;margin:0 0 20px}h3{font-size:24px;margin:8px 0 14px}a{color:inherit;text-underline-offset:4px}p{margin:12px 0}.eyebrow{text-transform:uppercase;letter-spacing:.17em;font-size:12px;font-weight:700}.toolbar{display:flex;justify-content:space-between;gap:20px}.toolbar a{font-size:14px}.intro{max-width:740px;font-size:20px;color:#dce4d5}.tags{display:flex;flex-wrap:wrap;gap:10px;margin-top:24px}.tags span{border:1px solid #728b7a;border-radius:25px;padding:5px 12px;font-size:13px}nav{display:flex;flex-wrap:wrap;gap:20px;border-bottom:1px solid var(--line);padding-bottom:22px;font-size:14px}section{padding-top:40px}.lead{font-family:Georgia,serif;font-size:25px;line-height:1.5}.grid{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:18px}.card{background:#fffdf7;border:1px solid var(--line);border-radius:12px;padding:24px}.card p{font-size:15px}.label{color:var(--accent);font-size:12px;text-transform:uppercase;letter-spacing:.1em;font-weight:750}.muted,small{color:var(--muted)}.note{border-left:3px solid var(--accent);padding:12px 20px;margin:24px 0;background:#eeeadd}.table-wrap{overflow-x:auto}table{width:100%;border-collapse:collapse;font-size:15px}th{text-align:left;background:#e6eadf}td,th{padding:13px;border-bottom:1px solid var(--line);vertical-align:top}li{padding:6px 0}.day{display:grid;grid-template-columns:100px 1fr;gap:20px;padding:18px 0;border-bottom:1px solid var(--line)}.day b{color:var(--accent)}footer{margin-top:45px;border-top:1px solid var(--line);padding-top:20px;font-size:13px}.button{display:inline-block;background:var(--ink);color:white;padding:10px 18px;border-radius:25px;text-decoration:none}.checklist{list-style:none;padding:0}.checklist li:before{content:'□';margin-right:12px;color:var(--accent)}@media(max-width:760px){.grid{grid-template-columns:1fr}.day{grid-template-columns:65px 1fr}main,header>div{padding-left:20px;padding-right:20px}td,th{padding:10px}.toolbar{flex-wrap:wrap}}@media print{header{background:white;color:black}.toolbar,nav{display:none}.intro{color:black}.card,.day{break-inside:avoid}main{padding:0}}`;
export function privateIndex(trips) {
  return `<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta name="robots" content="noindex,nofollow,noarchive"><title>Family travel plans</title><style>${css}</style></head><body><header><div><div class="eyebrow">Travel planning · Private collection</div><h1>Good trips start here.</h1><p class="intro">A considered collection of family itineraries, places to stay, and practical preparations. Every trip begins as a proposal.</p></div></header><main><section class="grid" aria-label="Trip plans">${trips.map(t => `<article class="card"><span class="label">${escapeHtml(t.status)}</span><h2><a href="/${t.slug}/">${escapeHtml(t.title)}</a></h2><p class="muted">${escapeHtml(t.dates)}</p><p>${escapeHtml(t.summary)}</p><a href="/${t.slug}/">Read the plan →</a></article>`).join('')}</section><footer>Family travel reference · Dates and availability remain subject to confirmation.</footer></main></body></html>`;
}
export function publicFiles(trips) {
  const result = { 'robots.txt': 'User-agent: *\nDisallow: /\n', '404.html': '<!doctype html><html lang="en"><head><meta name="robots" content="noindex,nofollow"><title>Not found</title></head><body>Not found</body></html>' };
  for (const t of trips) {
    if (!allowedSlug(t.slug)) throw Error('Invalid trip route');
    result[`${t.slug}/index.html`] = t.encrypted;
  }
  return result;
}
export async function loadTrips(directory, password) {
  const trips = [];
  for (const name of (await readdir(directory)).filter(n => n.endsWith('.html')).sort()) {
    const slug = name.slice(0, -5);
    if (!allowedSlug(slug)) throw Error('Invalid trip filename');
    const encrypted = await readFile(join(directory, name), 'utf8');
    const html = await decryptPage(encrypted, password);
    const info = metadata(html);
    if (slug !== info.slug) throw Error('Trip route mismatch');
    trips.push({ ...info, html, encrypted });
  }
  if (!trips.length) throw Error('Empty trip release');
  return trips;
}
export async function writePublic(directory, trips) {
  const hashes = {};
  for (const [name, text] of Object.entries(publicFiles(trips))) {
    await mkdir(join(directory, name, '..'), { recursive: true });
    await writeFile(join(directory, name), text);
    hashes[name] = createHash('sha256').update(text).digest('hex');
  }
  return hashes;
}
export async function writePrivate(directory, trips) {
  await mkdir(directory, { recursive: true, mode: 0o700 });
  await writeFile(join(directory, 'index.html'), privateIndex(trips), { mode: 0o600 });
  for (const trip of trips) {
    await mkdir(join(directory, trip.slug), { recursive: true, mode: 0o700 });
    const html = trip.html.replace('</head>', '<style>.private-only{display:inline!important}.public-only{display:none!important}</style></head>');
    await writeFile(join(directory, trip.slug, 'index.html'), html, { mode: 0o600 });
  }
}
