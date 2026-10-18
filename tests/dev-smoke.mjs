import assert from 'node:assert/strict';
import { chromium } from 'playwright';
import { createServer } from 'node:http';
import { readFile } from 'node:fs/promises';
import { resolve, sep, extname } from 'node:path';

let server;
let baseURL = process.env.SITE_BASE_URL || 'https://dev.robertboscacci.com/';
if (process.env.SITE_DIRECTORY) {
  const root = resolve(process.env.SITE_DIRECTORY);
  server = createServer(async (req, res) => {
    try {
      const pathname = decodeURIComponent(new URL(req.url, 'http://localhost').pathname);
      const file = resolve(root, '.' + pathname + (pathname.endsWith('/') ? 'index.html' : ''));
      if (!file.startsWith(root + sep)) throw new Error('Outside artifact');
      const types = { '.html': 'text/html', '.css': 'text/css', '.js': 'text/javascript', '.json': 'application/json', '.svg': 'image/svg+xml' };
      res.setHeader('Content-Type', types[extname(file)] || 'application/octet-stream');
      res.end(await readFile(file));
    } catch {
      res.writeHead(404).end();
    }
  });
  await new Promise(done => server.listen(0, '127.0.0.1', done));
  baseURL = `http://127.0.0.1:${server.address().port}/`;
}
const browser = await chromium.launch({ headless: true });
const page = await browser.newPage();
if (server) {
  // Hugo emits absolute dev links; exercise those links against this artifact.
  await page.route('https://dev.robertboscacci.com/**', async route => {
    const source = new URL(route.request().url());
    const response = await page.request.get(new URL(source.pathname + source.search, baseURL).href);
    await route.fulfill({ response });
  });
}
const checks = [
  ['elliott-bay-vhf', ['Whisper Large V3 Turbo', 'DockTalk', 'Eighteen', 'On dev']],
  ['meeting-mute-button', ['device identity', 'USB serial', 'laundry']],
  ['laundry-done', ['eight minutes', 'four minutes', 'encrypted', 'Missing packets']],
];
try {
  const home = await page.goto(baseURL);
  assert.equal(home.status(), 200);
  await page.getByRole('link', { name: 'Projects', exact: true }).first().click();
  await page.waitForURL('**/projects/');
  for (const [slug, phrases] of checks) {
    const link = page.locator(`a[href$="/projects/${slug}/"]`).first();
    await link.waitFor({ state: 'visible' });
    await link.click();
    await page.waitForURL(`**/projects/${slug}/`);
    const text = await page.locator('main').innerText();
    for (const phrase of phrases) assert.ok(text.includes(phrase), `${slug}: missing ${phrase}`);
    assert.match(await page.locator('meta[name="robots"]').getAttribute('content'), /noindex/);
    for (const width of [390, 1440]) {
      await page.setViewportSize({ width, height: 900 });
      assert.ok(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth + 1), `${slug}: overflow at ${width}`);
    }
    await page.goto(new URL('projects/', baseURL).href);
  }
  if (process.env.EXPECTED_COMMIT) {
    const response = await page.request.get(new URL('dev-release.json', baseURL).href, { headers: { 'Cache-Control': 'no-cache' } });
    assert.equal(response.status(), 200);
    assert.equal((await response.json()).commit, process.env.EXPECTED_COMMIT);
  }
  console.log(JSON.stringify({ event: 'dev_smoke_passed', baseURL, pages: checks.length, viewports: [390, 1440] }));
} catch (error) {
  await page.screenshot({ path: 'outputs/dev-smoke-failure.png', fullPage: true }).catch(() => {});
  throw error;
} finally {
  await browser.close();
  if (server) await new Promise(done => server.close(done));
}
