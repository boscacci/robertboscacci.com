import { randomBytes } from 'node:crypto';
import { readFile } from 'node:fs/promises';
import { createServer } from 'node:http';
import { performance } from 'node:perf_hooks';
import { DatabaseSync } from 'node:sqlite';
import { Readable } from 'node:stream';
import { pipeline } from 'node:stream/promises';
import { calendarDate, validDate } from './calendar.mjs';

const confirmationMs = 30_000;
const recentWindowMs = 30 * 86_400_000;
const securityHeaders = {
  'Cache-Control': 'no-store',
  'Content-Security-Policy': "default-src 'none'; style-src 'self'; script-src 'self'; connect-src 'self'; frame-ancestors 'none'; base-uri 'none'; form-action 'none'",
  'Referrer-Policy': 'no-referrer',
  'X-Content-Type-Options': 'nosniff',
  'X-Robots-Tag': 'noindex, nofollow, noarchive',
};
const files = {
  '/': ['index.html', 'text/html'],
  '/app.mjs': ['app.mjs', 'text/javascript'],
  '/calendar.mjs': ['calendar.mjs', 'text/javascript'],
  '/style.css': ['style.css', 'text/css'],
};

function identityFromServe(request) {
  const login = request.headers['tailscale-user-login'];
  return typeof login === 'string' && !login.includes(',') ? login : null;
}

function send(response, status, data, type = 'application/json') {
  response.writeHead(status, { ...securityHeaders, 'Content-Type': `${type}; charset=utf-8` });
  response.end(type === 'application/json' ? JSON.stringify(data) : data);
  return status;
}

async function readToken(request) {
  if (request.headers['content-type'] !== 'application/json') throw new Error('invalid_media_type');
  let body = '';
  request.setEncoding('utf8');
  for await (const chunk of request) {
    body += chunk;
    if (body.length > 256) throw new Error('body_too_large');
  }
  const data = JSON.parse(body);
  if (data?.token !== null && (typeof data?.token !== 'string' || !/^[a-f0-9]{32}$/.test(data.token))) throw new Error('invalid_token');
  return data.token;
}

export async function createCounter({ origin, viewOrigin, owner, database, initialDate, identify = identityFromServe, now = () => new Date(), log = record => console.log(JSON.stringify(record)) }) {
  const { host } = new URL(origin);
  if (!owner || !database || !validDate(initialDate) || (viewOrigin && new URL(viewOrigin).origin !== viewOrigin)) throw new Error('invalid_counter_configuration');
  const assets = new Map(await Promise.all(Object.entries(files).map(async ([path, [file, type]]) =>
    [path, [await readFile(new URL(file, import.meta.url)), type]],
  )));
  const db = new DatabaseSync(database);
  db.exec(`PRAGMA busy_timeout = 3000;
    CREATE TABLE IF NOT EXISTS counter (
      id INTEGER PRIMARY KEY CHECK (id = 1), start TEXT NOT NULL, revision INTEGER NOT NULL
    );
    CREATE TABLE IF NOT EXISTS reset_history (
      revision INTEGER PRIMARY KEY CHECK (revision > 0), reset_at INTEGER NOT NULL
    );
    CREATE INDEX IF NOT EXISTS reset_history_time ON reset_history (reset_at);`);
  db.prepare('INSERT OR IGNORE INTO counter VALUES (1, ?, 0)').run(initialDate);
  const get = db.prepare('SELECT start, revision FROM counter WHERE id = 1');
  const getWithHistory = db.prepare(`SELECT start, revision,
    (SELECT count(*) FROM reset_history) AS recorded,
    (SELECT count(*) FROM reset_history WHERE reset_at > ? AND reset_at <= ?) AS past30Days
    FROM counter WHERE id = 1`);
  const reset = db.prepare('UPDATE counter SET start = ?, revision = revision + 1 WHERE id = 1 AND revision = ?');
  const recordReset = db.prepare('INSERT INTO reset_history (revision, reset_at) VALUES (?, ?)');
  const recentResets = db.prepare('SELECT reset_at FROM reset_history WHERE revision <= ? ORDER BY revision DESC LIMIT 10');
  const exportPage = db.prepare('SELECT revision, reset_at FROM reset_history WHERE revision > ? AND revision <= ? ORDER BY revision LIMIT 128');
  const pending = new Map();

  function current(timestamp) {
    const row = timestamp === undefined ? get.get() : getWithHistory.get(timestamp - recentWindowMs, timestamp);
    if (!validDate(row?.start) || !Number.isSafeInteger(row.revision) || row.revision < 0) throw new Error('invalid_counter_state');
    return row;
  }

  function snapshot(canReset, instant) {
    const row = current(canReset ? instant.getTime() : undefined);
    const result = { start: row.start, today: calendarDate(instant), canReset };
    if (canReset) result.resetHistory = {
      total: row.revision, past30Days: row.past30Days, hasUndatedResets: row.recorded < row.revision,
      recent: recentResets.all(row.revision).map(({ reset_at }) => new Date(reset_at).toISOString()),
    };
    return result;
  }

  function* historyCsv(through) {
    yield 'reset_number,reset_at_utc\r\n';
    let after = 0;
    while (after < through) {
      const rows = exportPage.all(after, through);
      if (!rows.length) break;
      yield rows.map(({ revision, reset_at }) => `${revision},${new Date(reset_at).toISOString()}\r\n`).join('');
      after = rows.at(-1).revision;
    }
  }

  async function sendHistory(response) {
    // A fixed revision keeps concurrent resets out of an in-progress export.
    const { revision } = current();
    response.writeHead(200, {
      ...securityHeaders,
      'Content-Type': 'text/csv; charset=utf-8',
      'Content-Disposition': 'attachment; filename="howlong-resets.csv"',
    });
    await pipeline(Readable.from(historyCsv(revision), { objectMode: false }), response);
    return 200;
  }

  function commitReset(today, revision, timestamp) {
    db.exec('BEGIN IMMEDIATE');
    try {
      const applied = reset.run(today, revision).changes === 1;
      if (applied) recordReset.run(revision + 1, timestamp);
      db.exec('COMMIT');
      return applied;
    } catch (error) {
      // Older Node 22 versions do not expose isTransaction.
      if (db.isTransaction !== false) db.exec('ROLLBACK');
      throw error;
    }
  }

  function applyClick(token) {
    const instant = now();
    const timestamp = instant.getTime();
    const { revision } = current();
    for (const [key, attempt] of pending) {
      if (attempt.expires <= timestamp || attempt.revision !== revision) pending.delete(key);
    }
    const attempt = token === null ? { count: 0 } : pending.get(token);
    if (!attempt) return [409, { error: 'confirmation_expired' }];
    if (token !== null) pending.delete(token);
    if (attempt.count === 4) {
      if (!commitReset(calendarDate(instant), revision, timestamp)) return [409, { error: 'confirmation_expired' }];
      pending.clear();
      log({ event: 'howlong_reset', revision: revision + 1 });
      return [200, snapshot(true, instant)];
    }
    if (pending.size >= 32) return [429, { error: 'too_many_confirmations' }];
    const next = randomBytes(16).toString('hex');
    const count = attempt.count + 1;
    pending.set(next, { count, revision, expires: timestamp + confirmationMs });
    return [200, { token: next, remaining: 5 - count }];
  }

  async function handle(request, response) {
    // Serve sets the socket Host to localhost and overwrites X-Forwarded-Host.
    if ((request.headers['x-forwarded-host'] ?? request.headers.host) !== host) return send(response, 421, { error: 'unexpected_host' });
    if (request.method === 'GET' && request.url === '/healthz') {
      current();
      return send(response, 200, 'howlong-ok\n', 'text/plain');
    }
    const from = request.headers.origin;
    if (viewOrigin && from === viewOrigin && ['/api/counter', '/api/reset'].includes(request.url)) {
      response.setHeader('Access-Control-Allow-Origin', viewOrigin);
      response.setHeader('Vary', 'Origin');
      if (request.method === 'OPTIONS' && request.url === '/api/reset' && request.headers['access-control-request-method'] === 'POST') {
        response.setHeader('Access-Control-Allow-Methods', 'POST');
        response.setHeader('Access-Control-Allow-Headers', 'Content-Type');
        return send(response, 204, '', 'text/plain');
      }
    }
    const identity = await identify(request);
    if (!identity) return send(response, 403, { error: 'tailnet_identity_required' });
    if (request.method === 'GET') {
      const asset = assets.get(request.url);
      if (asset) return send(response, 200, ...asset);
      if (request.url === '/runtime.json') return send(response, 200, { apiOrigin: '' });
      if (request.url === '/api/counter') return send(response, 200, snapshot(identity === owner, now()));
      if (request.url === '/api/reset-history.csv') {
        if (identity !== owner) return send(response, 403, { error: 'history_forbidden' });
        return sendHistory(response);
      }
    }
    if (request.method === 'POST' && request.url === '/api/reset') {
      if (identity !== owner || !from || (from !== origin && from !== viewOrigin)) return send(response, 403, { error: 'reset_forbidden' });
      let token;
      try { token = await readToken(request); }
      catch { return send(response, 400, { error: 'invalid_confirmation' }); }
      return send(response, ...applyClick(token));
    }
    return send(response, 404, { error: 'not_found' });
  }

  const server = createServer({ requestTimeout: 5000, headersTimeout: 5000, maxHeaderSize: 8192 }, async (request, response) => {
    const start = performance.now();
    let status;
    try { status = await handle(request, response); }
    catch (error) {
      if (response.destroyed && error.code === 'ERR_STREAM_PREMATURE_CLOSE') return;
      log({ event: 'howlong_request_error', code: error.code ?? 'unexpected_error', action: 'Check service and counter database health' });
      status = 503;
      if (response.headersSent || response.destroyed) response.destroy();
      else send(response, status, { error: 'counter_unavailable' });
    }
    if (status >= 500 || request.url === '/api/reset') log({ event: 'howlong_request', status, durationMs: Math.round(performance.now() - start) });
  });
  let closing;
  return {
    server,
    close() {
      closing ??= new Promise((resolve, reject) => server.close(error => {
        db.close();
        if (error) reject(error);
        else resolve();
      }));
      return closing;
    },
  };
}
