import assert from 'node:assert/strict';
import { mkdtemp, readFile, rm } from 'node:fs/promises';
import { request as httpRequest } from 'node:http';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { DatabaseSync } from 'node:sqlite';
import test from 'node:test';
import { chromium } from 'playwright';
import { calendarDate, elapsed, validDate } from '../services/howlong/calendar.mjs';
import { createCounter } from '../services/howlong/server.mjs';

const origin = 'http://howlong.test';
const viewOrigin = 'http://tracker.test';
const owner = 'owner@example.test';
const initial = new Date('2031-11-18T20:00:00Z');
const initialDate = '2031-11-06';
const today = '2031-11-18';
const ownerHeaders = { 'Tailscale-User-Login': owner };
const emptyHistory = { total: 0, past30Days: 0, hasUndatedResets: false, recent: [] };
const recordedHistory = { total: 1, past30Days: 1, hasUndatedResets: false, recent: [initial.toISOString()] };
const csvPath = '/api/reset-history.csv';
const csvHeader = 'reset_number,reset_at_utc\r\n';

test('calendar units follow complete weeks, months and years, including leap days and short months', () => {
  assert.deepEqual(elapsed(initialDate, '2031-11-05'), [[0, 'day']]);
  assert.deepEqual(elapsed(initialDate, initialDate), [[0, 'day']]);
  assert.deepEqual(elapsed(initialDate, today), [[1, 'week'], [5, 'day']]);
  assert.deepEqual(elapsed(initialDate, '2031-12-15'), [[1, 'month'], [1, 'week'], [2, 'day']]);
  assert.deepEqual(elapsed('2026-01-31', '2026-02-28'), [[1, 'month']]);
  assert.deepEqual(elapsed('2026-01-31', '2026-03-30'), [[1, 'month'], [4, 'week'], [2, 'day']]);
  assert.deepEqual(elapsed('2024-02-29', '2025-04-04'), [[1, 'year'], [1, 'month'], [6, 'day']]);
  assert.equal(validDate('2026-02-29'), false);
  assert.equal(calendarDate(new Date('2026-11-19T07:59:59Z')), '2026-11-18');
  assert.equal(calendarDate(new Date('2026-11-19T08:00:00Z')), '2026-11-19');
});

async function fixture(t, { seed, ...options } = {}) {
  const dir = await mkdtemp(join(tmpdir(), 'howlong-test-'));
  t.after(() => rm(dir, { recursive: true, force: true }));
  const database = join(dir, 'counter.sqlite');
  if (seed) {
    const db = new DatabaseSync(database);
    try { seed(db); } finally { db.close(); }
  }
  const start = async () => {
    const counter = await createCounter({ origin, owner, initialDate, database, now: () => initial, log() {}, ...options });
    await new Promise(resolve => counter.server.listen(0, '127.0.0.1', resolve));
    const port = counter.server.address().port;
    function request(path, { headers, method, body } = {}) {
      return new Promise((resolve, reject) => {
        const outgoing = httpRequest({ host: '127.0.0.1', port, path, method, headers: { Host: 'howlong.test', ...headers } }, async incoming => {
          try {
            const chunks = [];
            for await (const chunk of incoming) chunks.push(chunk);
            resolve(new Response(incoming.statusCode === 204 ? null : Buffer.concat(chunks), { status: incoming.statusCode, headers: incoming.headers }));
          } catch (error) { reject(error); }
        });
        outgoing.on('error', reject);
        outgoing.end(body);
      });
    }
    return { counter, request, database };
  };
  return start;
}

function click(request, token = null, identity = ownerHeaders, from = origin) {
  return request('/api/reset', { method: 'POST', headers: { ...identity, Origin: from, 'Content-Type': 'application/json' }, body: JSON.stringify({ token }) });
}

async function confirmFour(request) {
  let token = null;
  for (let count = 0; count < 4; count++) token = (await (await click(request, token)).json()).token;
  return token;
}

test('only the owner sees reset access and a fifth fresh click updates every viewer and survives restart', async t => {
  const start = await fixture(t);
  const { counter, request } = await start();
  t.after(() => counter.close());
  const viewer = { 'Tailscale-User-Login': 'viewer@example.test' };
  assert.equal((await request('/api/counter')).status, 403);
  assert.deepEqual(await (await request('/api/counter', { headers: viewer })).json(), { start: initialDate, today, canReset: false });
  assert.deepEqual(await (await request('/api/counter', { headers: ownerHeaders })).json(), { start: initialDate, today, canReset: true, resetHistory: emptyHistory });
  assert.equal((await click(request, null, viewer)).status, 403);
  assert.equal((await click(request, null, { 'X-Howlong-Peer': owner })).status, 403);
  assert.equal((await click(request, null, ownerHeaders, 'https://elsewhere.test')).status, 403);
  assert.equal((await request('/api/counter', { headers: { ...ownerHeaders, Host: 'elsewhere.test' } })).status, 421);
  assert.equal((await request('/api/counter', { headers: { ...ownerHeaders, Host: 'localhost', 'X-Forwarded-Host': 'howlong.test' } })).status, 200);
  let token = null;
  for (let count = 1; count <= 4; count++) {
    const response = await click(request, token);
    assert.equal(response.status, 200);
    const progress = await response.json();
    if (token) assert.equal((await click(request, token)).status, 409);
    assert.equal(progress.remaining, 5 - count);
    assert.equal((await (await request('/api/counter', { headers: viewer })).json()).start, initialDate);
    token = progress.token;
  }
  assert.deepEqual((await (await request('/api/counter', { headers: ownerHeaders })).json()).resetHistory, emptyHistory);
  assert.deepEqual(await (await click(request, token)).json(), { start: today, today, canReset: true, resetHistory: recordedHistory });
  assert.equal((await click(request, token)).status, 409);
  await counter.close();
  const restarted = await start();
  t.after(() => restarted.counter.close());
  assert.deepEqual(await (await restarted.request('/api/counter', { headers: viewer })).json(), { start: today, today, canReset: false });
  assert.deepEqual((await (await restarted.request('/api/counter', { headers: ownerHeaders })).json()).resetHistory, recordedHistory);
});

test('legacy resets remain in the total and individual resets age out of the 30-day window', async t => {
  let now = initial.getTime();
  const start = await fixture(t, {
    now: () => new Date(now),
    seed(db) {
      db.exec('CREATE TABLE counter (id INTEGER PRIMARY KEY CHECK (id = 1), start TEXT NOT NULL, revision INTEGER NOT NULL)');
      db.prepare('INSERT INTO counter VALUES (1, ?, 3)').run(initialDate);
    },
  });

  const { counter, request } = await start();
  t.after(() => counter.close());
  const history = async () => (await (await request('/api/counter', { headers: ownerHeaders })).json()).resetHistory;
  assert.deepEqual(await history(), { total: 3, past30Days: 0, hasUndatedResets: true, recent: [] });
  assert.equal((await click(request, await confirmFour(request))).status, 200);
  now += 1000;
  assert.equal((await click(request, await confirmFour(request))).status, 200);
  const later = new Date(now).toISOString();
  const saved = { total: 5, past30Days: 2, hasUndatedResets: true, recent: [later, initial.toISOString()] };
  assert.deepEqual(await history(), saved);
  now = initial.getTime() + 30 * 86_400_000;
  assert.deepEqual(await history(), { ...saved, past30Days: 1 });
  now += 1000;
  assert.deepEqual(await history(), { ...saved, past30Days: 0 });
  const exportResponse = await request(csvPath, { headers: ownerHeaders });
  assert.equal(await exportResponse.text(), `${csvHeader}4,${initial.toISOString()}\r\n5,${later}\r\n`);
});

test('only the owner can export every dated reset while the page gets a bounded recent list', async t => {
  const start = await fixture(t, { viewOrigin });
  const { counter, request, database } = await start();
  t.after(() => counter.close());
  const download = () => request(csvPath, { headers: ownerHeaders });
  assert.equal(await (await download()).text(), csvHeader);
  assert.equal((await request(csvPath)).status, 403);
  assert.equal((await request(csvPath, { headers: { Origin: viewOrigin, 'Tailscale-User-Login': 'viewer@example.test' } })).status, 403);

  const timestamps = Array.from({ length: 140 }, (_, index) => initial.getTime() - (139 - index) * 1234);
  const db = new DatabaseSync(database);
  try {
    db.exec('BEGIN');
    const add = db.prepare('INSERT INTO reset_history (revision, reset_at) VALUES (?, ?)');
    timestamps.forEach((timestamp, index) => add.run(index + 1, timestamp));
    db.prepare('UPDATE counter SET revision = ? WHERE id = 1').run(timestamps.length);
    db.exec('COMMIT');
  } finally { db.close(); }

  const iso = timestamps.map(timestamp => new Date(timestamp).toISOString());
  const details = (await (await request('/api/counter', { headers: ownerHeaders })).json()).resetHistory;
  assert.deepEqual(details.recent, iso.slice(-10).reverse());
  const response = await download();
  assert.equal(response.status, 200);
  assert.match(response.headers.get('content-type'), /^text\/csv\b/);
  assert.equal(response.headers.get('content-disposition'), 'attachment; filename="howlong-resets.csv"');
  assert.equal(response.headers.get('cache-control'), 'no-store');
  assert.equal(await response.text(), csvHeader + iso.map((time, index) => `${index + 1},${time}\r\n`).join(''));
});

test('a failed history insert rolls the date back and a fresh confirmation records exactly one reset', async t => {
  const start = await fixture(t);
  const { counter, request, database } = await start();
  t.after(() => counter.close());
  const db = new DatabaseSync(database);
  try {
    db.exec(`CREATE TRIGGER reject_history BEFORE INSERT ON reset_history
      BEGIN SELECT RAISE(ABORT, 'fixture history write failure'); END;`);
    const token = await confirmFour(request);
    assert.equal((await click(request, token)).status, 503);
    assert.deepEqual(await (await request('/api/counter', { headers: ownerHeaders })).json(), { start: initialDate, today, canReset: true, resetHistory: emptyHistory });
    db.exec('DROP TRIGGER reject_history');
    assert.equal((await click(request, token)).status, 409);
    const retry = await click(request, await confirmFour(request));
    assert.deepEqual((await retry.json()).resetHistory, recordedHistory);
    assert.equal(db.prepare('SELECT reset_at FROM reset_history WHERE revision = 1').get().reset_at, initial.getTime());
  } finally { db.close(); }
});

test('confirmation expires, rejects invalid bodies and invalidates simultaneous stale confirmations', async t => {
  let now = initial.getTime();
  const start = await fixture(t, { now: () => new Date(now) });
  const { counter, request } = await start();
  t.after(() => counter.close());
  assert.equal((await click(request, 42)).status, 400);
  let token = (await (await click(request)).json()).token;
  now += 31_000;
  assert.equal((await click(request, token)).status, 409);
  token = null;
  let other = null;
  for (let count = 1; count <= 4; count++) {
    token = (await (await click(request, token)).json()).token;
    other = (await (await click(request, other)).json()).token;
  }
  const results = await Promise.all([click(request, token), click(request, other)]);
  assert.deepEqual(results.map(response => response.status).sort(), [200, 409]);
  const state = await (await request('/api/counter', { headers: ownerHeaders })).json();
  const resetAt = new Date(now).toISOString();
  assert.deepEqual(state.resetHistory, { ...recordedHistory, recent: [resetAt] });
});

test('the vanity origin can use the private API while other origins and non-owners cannot reset', async t => {
  const start = await fixture(t, { viewOrigin });
  const { counter, request } = await start();
  t.after(() => counter.close());
  const preflight = await request('/api/reset', { method: 'OPTIONS', headers: {
    Origin: viewOrigin, 'Access-Control-Request-Method': 'POST', 'Access-Control-Request-Headers': 'content-type',
  } });
  assert.equal(preflight.status, 204);
  assert.equal(preflight.headers.get('access-control-allow-origin'), viewOrigin);
  assert.equal((await click(request, null, ownerHeaders, 'http://tracker.test.attacker.test')).status, 403);
  assert.equal((await click(request, null, { 'Tailscale-User-Login': 'viewer@example.test' }, viewOrigin)).status, 403);
  const response = await click(request, null, ownerHeaders, viewOrigin);
  assert.equal(response.status, 200);
  assert.equal(response.headers.get('access-control-allow-origin'), viewOrigin);
  assert.equal((await response.json()).remaining, 4);
});

async function browserFixture(t) {
  const start = await fixture(t, { viewOrigin });
  const { counter, request } = await start();
  t.after(() => counter.close());
  const browser = await chromium.launch();
  t.after(() => browser.close());

  async function open(login, { pageOrigin = origin, beforeReset, captureHaptics = false } = {}) {
    const page = await browser.newPage({ viewport: { width: 360, height: 740 }, isMobile: true, hasTouch: true });
    await page.clock.install();
    if (captureHaptics) await page.addInitScript(() => {
      window.vibrations = [];
      navigator.vibrate = duration => { window.vibrations.push(duration); return true; };
    });
    const handle = async route => {
      const incoming = route.request();
      const { pathname } = new URL(incoming.url());
      if (pageOrigin !== origin && incoming.url() === `${pageOrigin}/runtime.json`) {
        await route.fulfill({ json: { apiOrigin: origin } });
        return;
      }
      if (pathname === '/api/reset' && incoming.method() === 'POST') {
        const replacement = await beforeReset?.();
        if (replacement) return route.fulfill(replacement);
      }
      const response = await request(pathname, {
        method: incoming.method(), body: incoming.postData(),
        headers: { ...incoming.headers(), 'Tailscale-User-Login': login },
      });
      const headers = Object.fromEntries(response.headers);
      if (pageOrigin !== origin && pathname === '/') headers['content-security-policy'] = headers['content-security-policy'].replace("connect-src 'self'", `connect-src 'self' ${origin}`);
      await route.fulfill({ status: response.status, headers, body: Buffer.from(await response.arrayBuffer()) });
    };
    await page.route(`${origin}/**`, handle);
    if (pageOrigin !== origin) await page.route(`${pageOrigin}/**`, handle);
    await page.goto(pageOrigin);
    await page.locator('#since time').waitFor();
    return page;
  }
  return { open, request };
}

test('the mobile reset control shows each click, warns on the fifth and updates the read-only view', async t => {
  const { open, request } = await browserFixture(t);
  const viewer = await open('viewer@example.test');
  assert.equal(await viewer.locator('#reset-button').isVisible(), false);
  assert.equal(await viewer.getByRole('region', { name: 'Reset history' }).count(), 0);
  const admin = await open(owner, { pageOrigin: viewOrigin });
  const button = admin.getByRole('button', { name: 'Reset to today' });
  await button.waitFor();
  await admin.getByRole('region', { name: 'Reset history' }).waitFor();
  assert.equal(await admin.locator('#reset-total').textContent(), '0');
  assert.equal(await admin.getByText('No timestamped resets yet.').isVisible(), true);
  assert.deepEqual(await admin.locator('.unit').allTextContents(), ['1week', '5days']);
  assert.equal(await admin.evaluate(() => document.documentElement.scrollWidth), 360);
  for (let count = 1; count <= 4; count++) {
    await button.click();
    await admin.locator(`.steps i:nth-child(${count})[data-filled]`).waitFor();
    assert.equal(await admin.locator('#since time').getAttribute('datetime'), initialDate);
  }
  assert.match(await admin.locator('#reset-status').textContent(), /One more click/);
  await admin.getByRole('button', { name: 'Confirm reset' }).click();
  await admin.getByText('Counter reset to today for everyone.').waitFor();
  assert.equal(await admin.locator('.unit').textContent(), '0days');
  assert.equal(await admin.locator('#reset-total').textContent(), '1');
  assert.equal(await admin.locator('#reset-recent').textContent(), '1');
  assert.equal(await admin.locator('#reset-timestamps time').getAttribute('datetime'), initial.toISOString());
  const [download] = await Promise.all([
    admin.waitForEvent('download'), admin.getByRole('link', { name: 'Download CSV' }).click(),
  ]);
  assert.equal(download.suggestedFilename(), 'howlong-resets.csv');
  assert.equal(await readFile(await download.path(), 'utf8'), `${csvHeader}1,${initial.toISOString()}\r\n`);
  assert.equal((await click(request, await confirmFour(request))).status, 200);
  await admin.clock.fastForward(11_000);
  await admin.waitForFunction(() => document.querySelector('#reset-total').textContent === '2');
  await viewer.clock.fastForward(11_000);
  await viewer.locator(`#since time[datetime="${today}"]`).waitFor();
  assert.equal(await viewer.getByRole('region', { name: 'Reset history' }).count(), 0);
  assert.equal(await viewer.getByRole('link', { name: 'Download CSV' }).count(), 0);
});

test('rapid touch taps respond immediately and queue exactly five confirmations through a slow response', async t => {
  const { open, request } = await browserFixture(t);
  const firstRequest = Promise.withResolvers();
  const releaseResponse = Promise.withResolvers();
  let posts = 0;
  const page = await open(owner, {
    captureHaptics: true,
    beforeReset: async () => {
      if (++posts !== 1) return;
      firstRequest.resolve();
      await releaseResponse.promise;
    },
  });
  const button = page.locator('#reset-button');
  const box = await button.boundingBox();
  const tap = () => page.touchscreen.tap(box.x + box.width / 2, box.y + box.height / 2);
  try {
    await tap();
    await firstRequest.promise;
    for (let count = 2; count <= 4; count++) await tap();
    assert.equal(await button.locator('[data-filled]').count(), 4);
    assert.equal(await button.getAttribute('data-final'), '');
    assert.match(await page.locator('#reset-status').textContent(), /One more click/);
    for (let count = 5; count <= 7; count++) await tap();
    assert.equal(await button.locator('[data-filled]').count(), 5);
    assert.equal(await button.getAttribute('aria-disabled'), 'true');
    const pulses = await page.evaluate(() => window.vibrations);
    assert.equal(pulses.length, 5);
    assert.ok(pulses[4] > pulses[0]);
    assert.equal((await (await request('/api/counter', { headers: ownerHeaders })).json()).start, initialDate);
  } finally {
    releaseResponse.resolve();
  }
  await page.getByText('Counter reset to today for everyone.').waitFor();
  assert.equal(posts, 5);
  assert.equal(await page.locator('#since time').getAttribute('datetime'), today);
});

test('an expired confirmation clears the queued taps without replaying them', async t => {
  const { open, request } = await browserFixture(t);
  const response = Promise.withResolvers();
  let posts = 0;
  const page = await open(owner, { beforeReset: () => { posts++; return response.promise; } });
  const button = page.getByRole('button', { name: 'Reset to today' });
  try {
    await button.tap();
    await button.tap();
    await button.tap();
    assert.equal(await button.locator('[data-filled]').count(), 3);
  } finally {
    response.resolve({ status: 409, json: { error: 'confirmation_expired' } });
  }
  await page.getByText('Confirmation expired. Click five times to start again.').waitFor();
  assert.equal(posts, 1);
  assert.equal(await button.locator('[data-filled]').count(), 0);
  assert.equal((await (await request('/api/counter', { headers: ownerHeaders })).json()).start, initialDate);
});

test('public cloud reads expose only the counter, even with forged owner headers', async t => {
  const start = await fixture(t, { publicOrigin: viewOrigin, viewOrigin });
  const { counter, request } = await start();
  t.after(() => counter.close());
  const publicHeaders = { Host: 'tracker.test', ...ownerHeaders, 'X-Howlong-User': 'owner' };
  assert.equal((await request('/', { headers: publicHeaders })).status, 200);
  assert.deepEqual(await (await request('/api/counter', { headers: publicHeaders })).json(), { start: initialDate, today, canReset: false });
  assert.equal((await click(request, null, publicHeaders, viewOrigin)).status, 403);
  assert.equal((await request(csvPath, { headers: publicHeaders })).status, 403);
  assert.equal((await (await request('/api/counter', { headers: ownerHeaders })).json()).canReset, true);
  assert.equal((await request('/api/counter')).status, 403);
});

test('public page discovers an owner on the private origin and stays usable off tailnet', async t => {
  const { counter, request } = await (await fixture(t, { publicOrigin: viewOrigin, viewOrigin }))();
  t.after(() => counter.close());
  const browser = await chromium.launch();
  t.after(() => browser.close());
  for (const onTailnet of [false, true]) {
    const page = await browser.newPage();
    const handle = async route => {
      const incoming = route.request();
      const url = new URL(incoming.url());
      if (url.origin === origin && !onTailnet) return route.abort();
      const headers = { ...incoming.headers(), Host: url.host };
      if (url.origin === origin) Object.assign(headers, ownerHeaders);
      const response = await request(url.pathname, { headers, method: incoming.method(), body: incoming.postData() });
      await route.fulfill({ status: response.status, headers: Object.fromEntries(response.headers), body: Buffer.from(await response.arrayBuffer()) });
    };
    await page.route(viewOrigin + '/**', handle);
    await page.route(origin + '/**', handle);
    const probe = page.waitForRequest(origin + '/api/counter');
    await page.goto(viewOrigin);
    await probe;
    await page.locator('#since time').waitFor();
    if (onTailnet) {
      await page.locator('#reset-button').click();
      await page.waitForFunction(() => document.querySelector('#reset-status').textContent.includes('4 more'));
      assert.equal(await page.locator('#history-download').getAttribute('href'), origin + csvPath);
    } else {
      assert.equal(await page.locator('#reset-button').isVisible(), false);
      assert.equal(await page.locator('#reset-history').isVisible(), false);
    }
    await page.close();
  }
});
