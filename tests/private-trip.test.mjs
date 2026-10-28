import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { randomBytes } from 'node:crypto';
import { decryptPage, encryptPage } from '../scripts/private-trip.mjs';

test('private trip encrypts content without exposing password or allowing remembered access', async () => {
  const dir = await mkdtemp(join(tmpdir(), 'trip-test-'));
  try {
    const password = randomBytes(24).toString('base64url');
    const file = join(dir, 'index.html');
    await encryptPage('<!doctype html><html><head></head><body>PRIVATE_SENTINEL</body></html>', password, file);
    const output = await readFile(file, 'utf8');
    assert.ok(!output.includes('PRIVATE_SENTINEL'));
    assert.ok(!output.includes(password));
    assert.match(output, /noindex, nofollow, noarchive/);
    assert.match(output, /Content-Security-Policy/);
    assert.match(output, /isRememberEnabled":false/);
    assert.match(output, /referrer.*no-referrer/);
    assert.equal(await decryptPage(output, password), '<!doctype html><html><head></head><body>PRIVATE_SENTINEL</body></html>');
  } finally { await rm(dir, { recursive: true, force: true }); }
});

test('private trip decrypts with the embedded salt without a local config and rejects invalid credentials or ciphertext', async () => {
  const dir = await mkdtemp(join(tmpdir(), 'trip-test-'));
  try {
    const file = join(dir, 'index.html');
    const password = randomBytes(24).toString('base64url');
    await encryptPage('<html>private editing round trip</html>', password, file);
    const encrypted = await readFile(file, 'utf8');
    assert.equal(await decryptPage(encrypted, password), '<html>private editing round trip</html>');
    await assert.rejects(decryptPage(encrypted, 'wrong-password'), /decrypt/i);
    await assert.rejects(decryptPage('not an encrypted page', password), /encrypted/i);
  } finally { await rm(dir, { recursive: true, force: true }); }
});

test('private trip refuses missing and weak passwords before changing the output', async () => {
  const dir = await mkdtemp(join(tmpdir(), 'trip-test-'));
  const file = join(dir, 'index.html');
  try {
    await writeFile(file, 'previous encrypted release');
    for (const password of ['', 'short', undefined]) {
      await assert.rejects(encryptPage('<html>secret</html>', password, file), /password/i);
      assert.equal(await readFile(file, 'utf8'), 'previous encrypted release');
    }
  } finally { await rm(dir, { recursive: true, force: true }); }
});
