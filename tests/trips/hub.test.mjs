import { test } from 'node:test';
import assert from 'node:assert/strict';
import { privateIndex, metadata, allowedSlug, publicFiles } from '../../services/trips/hub.mjs';

test('trip routing accepts only a single canonical slug', () => {
  for (const slug of ['puerto-vallarta-2027', 'north-cascades-2027']) assert.ok(allowedSlug(slug));
  for (const slug of ['../secrets', '/index', 'foo/bar', 'index', 'healthz', '', 'ABC']) assert.ok(!allowedSlug(slug));
});
test('private index escapes trip content and links only to canonical routes', () => {
  const html = privateIndex([{ slug: 'test-2027', title: '<script>alert(1)</script>', dates: 'TBD', status: 'Planning', summary: 'One & two' }]);
  assert.ok(html.includes('&lt;script&gt;'));
  assert.ok(!html.includes('<script>alert'));
  assert.ok(html.includes('href="/test-2027/"'));
  assert.ok(html.includes('noindex'));
});
test('metadata rejects absent fields and malicious slugs before publishing', () => {
  assert.throws(() => metadata('<html></html>'), /metadata/);
  assert.throws(() => metadata('<script id="trip-metadata" type="application/json">{"slug":"../x"}</script>'), /metadata/);
  const trip = { slug: 'test-2027', title: 'Test', dates: 'TBD', status: 'Planning', summary: 'Draft' };
  assert.deepEqual(metadata(`<script id="trip-metadata" type="application/json">${JSON.stringify(trip)}</script>`), trip);
});
test('public release contains encrypted trip routes and discovery controls, never an index', () => {
  const files = publicFiles([{ slug: 'test-2027', encrypted: '<html>ciphertext</html>' }]);
  assert.equal(files['test-2027/index.html'], '<html>ciphertext</html>');
  assert.ok(!('index.html' in files));
  assert.match(files['robots.txt'], /Disallow: \//);
  assert.ok(!Object.values(files).some(v => v.includes('private-index')));
});
