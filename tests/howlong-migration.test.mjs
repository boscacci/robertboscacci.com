import assert from 'node:assert/strict';
import { mkdir, mkdtemp, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { DatabaseSync } from 'node:sqlite';
import test from 'node:test';
import { counterFingerprint, snapshotCounter } from '../scripts/howlong-migration.mjs';

test('a legacy production snapshot matches after adding empty history, but a new reset changes the fingerprint', async () => {
  const dir = await mkdtemp(join(tmpdir(), 'howlong-migration-'));
  try {
    await mkdir(join(dir, 'cloud'));
    const source = join(dir, 'counter.sqlite');
    const candidate = join(dir, 'cloud', 'counter.sqlite');
    const legacy = new DatabaseSync(source);
    legacy.exec(`CREATE TABLE counter (id INTEGER PRIMARY KEY, start TEXT, revision INTEGER);
      INSERT INTO counter VALUES (1, '2026-11-07', 3);`);
    legacy.close();
    const fingerprint = await snapshotCounter(source, candidate);

    const cloud = new DatabaseSync(candidate);
    cloud.exec('CREATE TABLE reset_history (revision INTEGER PRIMARY KEY, reset_at INTEGER);');
    assert.equal(counterFingerprint(candidate), fingerprint);
    cloud.exec('INSERT INTO reset_history VALUES (3, 1794081600000);');
    assert.notEqual(counterFingerprint(candidate), fingerprint);
    assert.equal(counterFingerprint(source), fingerprint);
    cloud.close();
    assert.throws(() => counterFingerprint(join(dir, 'absent.sqlite')));
  } finally {
    await rm(dir, { recursive: true, force: true });
  }
});
