import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { mkdtemp, readFile, readdir, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import test from 'node:test';
import { chromium } from 'playwright';

const expected = "G-KVWJR6HZTX"; // Public browser identifier, never an account credential.
async function htmlFiles(dir) {
  const files = [];
  for (const item of await readdir(dir, { withFileTypes: true })) {
    const path = join(dir, item.name);
    if (item.isDirectory()) files.push(...await htmlFiles(path));
    else if (item.name.endsWith('.html')) files.push(path);
  }
  return files;
}

test('configured analytics uses the current measurement ID on every Hugo page, with no duplicate tags', async () => {
  const dir = await mkdtemp(join(tmpdir(), 'site-analytics-'));
  try {
    const config = await readFile('config/_default/config.toml', 'utf8');
    assert.ok(config.includes('id = "' + expected + '"'), 'Hugo must use the current measurement ID');
    for (const environment of ['production', 'development']) {
      const destination = join(dir, environment);
      execFileSync('hugo', ['--environment', environment, '--destination', destination, '--minify'], { stdio: 'pipe' });
      let checked = 0;
      for (const file of await htmlFiles(destination)) {
        const html = await readFile(file, 'utf8');
        // Hugo aliases redirect to a real page; static encrypted pages have their own security boundary.
        if (file.includes('/private/') || /http-equiv=["']?refresh/i.test(html)) continue;
        const tags = [...html.matchAll(/<script[^>]+src=["']?https:\/\/www\.googletagmanager\.com\/gtag\/js\?id=([^"' >]+)/g)];
        assert.equal(tags.length, environment === 'production' ? 1 : 0, file);
        if (tags.length) {
          assert.equal(tags[0][1], expected, file);
          assert.ok(html.indexOf('googletagmanager.com/gtag/js') < html.indexOf('</head>'), file);
        }
        checked++;
      }
      assert.ok(checked > 20, 'Must check home, articles, lists, taxonomy, pagination and 404');
      console.log(JSON.stringify({ event: 'analytics_pages_verified', environment, pages: checked }));
    }
    // Exercise actual inline initialization without sending test traffic to Google.
    const browser = await chromium.launch();
    try {
      const page = await browser.newPage();
      await page.route('**/*', route => route.fulfill({ body: '', contentType: 'text/javascript' }));
      const html = await readFile(join(dir, 'production/index.html'), 'utf8');
      await page.setContent(html);
      const calls = await page.evaluate(() => Array.from(window.dataLayer ?? [], call => Array.from(call)));
      assert.equal(calls.filter(call => call[0] === 'config' && call[1] === expected).length, 1);
    } finally { await browser.close(); }
  } finally { await rm(dir, { recursive: true, force: true }); }
});
