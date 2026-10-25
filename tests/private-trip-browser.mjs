import assert from 'node:assert/strict';
import { createServer } from 'node:http';
import { readFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { createHash, randomBytes } from 'node:crypto';
import { mkdtemp, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { chromium } from 'playwright';
import { encryptPage, pagePath, readPassword } from '../scripts/private-trip.mjs';

export async function smoke(url, password) {
  const browser = await chromium.launch();
  try {
    const page = await browser.newPage({ viewport: { width: 390, height: 844 } });
    page.setDefaultTimeout(10000);
    const unexpectedRequests = [];
    const errors = [];
    page.on('request', (request) => {
      if (!request.isNavigationRequest() && !request.url().startsWith('data:')) unexpectedRequests.push(true);
    });
    page.on('pageerror', () => errors.push(true));
    const response = await page.goto(url);
    assert.equal(response.status(), 200);
    const encrypted = await response.text();
    assert.ok(!encrypted.includes('Little campers.'));
    assert.ok(!encrypted.includes(password));
    await page.locator('#staticrypt-password').waitFor({ state: 'visible' });
    assert.equal(await page.locator('#staticrypt-remember').isVisible(), false);
    // Wrong password must fail closed before any trip content is displayed.
    const wrong = page.waitForEvent('dialog');
    await page.locator('#staticrypt-password').fill('definitely-not-the-family-password');
    await page.getByRole('button', { name: 'Open trip plan' }).click();
    await (await wrong).accept();
    assert.equal(await page.locator('h1').count(), 0);
    // Never retain traces: Playwright action logs can contain password input values.
    try {
      await page.locator('#staticrypt-password').fill(password);
      await page.getByRole('button', { name: 'Open trip plan' }).click();
      await page.getByRole('heading', { name: /Little campers/ }).waitFor();
    } catch { throw new Error('Password unlock smoke check failed (sensitive action details suppressed).'); }
    assert.ok(await page.getByRole('heading', { name: 'Where we’d love to land' }).isVisible());
    assert.ok(await page.getByText('Two neighboring tent sites', { exact: true }).isVisible());
    assert.equal(await page.evaluate(() => document.documentElement.scrollWidth > innerWidth), false);
    assert.equal(await page.evaluate(() => localStorage.length), 0);
    assert.equal(await page.evaluate(() => sessionStorage.length), 0);
    await page.getByRole('link', { name: 'Lock page', exact: true }).click();
    await page.locator('#staticrypt-password').waitFor({ state: 'visible' });
    assert.equal(await page.locator('h1').count(), 0);
    // An altered encrypted message must fail authentication even with the right password.
    await page.route('**/*', async (route) => {
      if (route.request().isNavigationRequest()) {
        let altered = encrypted.replace(/("staticryptEncryptedMsgUniqueVariableName":\s*")([a-f0-9])/, (_, prefix, digit) => prefix + (digit === 'a' ? 'b' : 'a'));
        assert.notEqual(altered, encrypted);
        // Update CSP so the codec's authentication is exercised, beyond CSP's own protection.
        const script = altered.match(/<script>([\s\S]*?)<\/script>/)[1];
        altered = altered.replace(/script-src [^;]+;/, `script-src 'sha256-${createHash('sha256').update(script).digest('base64')}';`);
        await route.fulfill({ body: altered, contentType: 'text/html' });
      } else await route.continue();
    });
    await page.goto(url);
    await page.locator('#staticrypt-password').waitFor({ state: 'visible' });
    const tampered = page.waitForEvent('dialog');
    try {
      await page.locator('#staticrypt-password').fill(password);
      await page.getByRole('button', { name: 'Open trip plan' }).click();
      await (await tampered).accept();
    } catch { throw new Error('Tampered payload smoke check failed (sensitive action details suppressed).'); }
    assert.equal(await page.locator('h1').count(), 0);
    assert.equal(unexpectedRequests.length, 0);
    assert.equal(errors.length, 0);
  } finally { await browser.close(); }
}

async function main() {
  const fixture = process.argv[2] === '--fixture';
  const remote = fixture ? null : process.argv[2];
  let server;
  let temporary;
  try {
    let url = remote;
    const password = fixture ? randomBytes(24).toString('base64url') : readPassword();
    if (!url) {
      let file = new URL(`../static/${pagePath}`, import.meta.url);
      if (fixture) {
        temporary = await mkdtemp(join(tmpdir(), 'trip-browser-'));
        file = join(temporary, 'index.html');
        await encryptPage('<!doctype html><html lang="en"><head><title>Test</title></head><body><h1>Little campers.</h1><h2>Where we’d love to land</h2><span>Two neighboring tent sites</span><a href="./?locked=1">Lock page</a></body></html>', password, file);
      }
      const html = await readFile(file);
      server = createServer((request, response) => {
        response.setHeader('Content-Type', 'text/html; charset=utf-8');
        response.end(html);
      });
      await new Promise((done) => server.listen(0, '127.0.0.1', done));
      url = `http://127.0.0.1:${server.address().port}/${pagePath.replace('index.html', '')}`;
    }
    await smoke(url, password);
    console.log(JSON.stringify({ event: 'trip_smoke_passed', target: remote ? 'dev' : 'local', checks: ['wrong_password', 'unlock', 'mobile', 'lock', 'tamper', 'no_storage', 'no_external_requests'] }));
  } finally {
    if (server) await new Promise((done) => server.close(done));
    if (temporary) await rm(temporary, { recursive: true, force: true });
  }
}
if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  main().catch((error) => { console.error(error.message); process.exitCode = 1; });
}
