import assert from 'node:assert/strict';
import { chromium } from 'playwright';

export async function smoke(baseURL, commit, measurementID = null) {
  const browser = await chromium.launch();
  try {
    const page = await browser.newPage();
    // Verify initialization without creating synthetic analytics traffic from dev.
    await page.route(/googletagmanager\.com|google-analytics\.com/, route => route.fulfill({ body: '', contentType: 'text/javascript' }));
    for (const path of ['/', '/blog/', '/projects/', '/404.html']) {
      const response = await page.goto(new URL(`${path}?release=${commit}`, baseURL).href);
      assert.equal(response.status(), 200, path);
      assert.ok(await page.title(), path);
      await page.locator('main').waitFor();
      assert.equal(await page.locator('script[src*="googletagmanager.com/gtag/js"]').count(), measurementID ? 1 : 0, path);
      if (measurementID) {
        const configs = await page.evaluate(() => Array.from(window.dataLayer ?? [], call => Array.from(call)).filter(call => call[0] === 'config').map(call => call[1]));
        assert.deepEqual(configs, [measurementID], path);
      } else assert.match(await page.locator('meta[name="robots"]').getAttribute('content'), /noindex/);
      assert.match(response.headers()['x-robots-tag'], /noindex/);
    }
  } finally { await browser.close(); }
}
