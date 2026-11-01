import assert from 'node:assert/strict';
import { chromium } from 'playwright';

export async function smoke(baseURL, commit) {
  const browser = await chromium.launch();
  try {
    const page = await browser.newPage();
    for (const path of ['/', '/blog/', '/projects/', '/404.html']) {
      const response = await page.goto(new URL(`${path}?release=${commit}`, baseURL).href);
      assert.equal(response.status(), 200, path);
      assert.ok(await page.title(), path);
      await page.locator('main').waitFor();
      assert.equal(await page.locator('script[src*="googletagmanager.com/gtag/js"]').count(), 0, path);
      assert.match(await page.locator('meta[name="robots"]').getAttribute('content'), /noindex/);
      assert.match(response.headers()['x-robots-tag'], /noindex/);
    }
  } finally { await browser.close(); }
}
