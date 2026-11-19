import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { mkdtemp, readFile, readdir, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { DatabaseSync } from 'node:sqlite';
import test from 'node:test';
import { createS3Writer, syncHistory } from '../services/howlong/archive.mjs';

const timestamp = Date.parse('2031-11-18T20:00:00.123Z');

async function fixture(t) {
  const directory = await mkdtemp(join(tmpdir(), 'howlong-archive-test-'));
  t.after(() => rm(directory, { recursive: true, force: true }));
  const database = join(directory, 'counter.sqlite');
  const db = new DatabaseSync(database);
  t.after(() => db.close());
  db.exec('CREATE TABLE reset_history (revision INTEGER PRIMARY KEY, reset_at INTEGER NOT NULL)');
  return { directory, database, add: db.prepare('INSERT INTO reset_history VALUES (?, ?)') };
}

test('backfill and retry archive each dated reset, including a late earlier timestamp', async t => {
  const { database, add } = await fixture(t);
  const remote = new Map();
  const upload = async ({ key, body }) => {
    if (remote.has(key)) assert.equal(remote.get(key), body);
    remote.set(key, body);
  };
  add.run(2, timestamp);
  add.run(3, timestamp + 100);
  const attempted = [];
  await assert.rejects(syncHistory({ database, upload: async object => {
    attempted.push(object.key);
    await upload(object);
    if (attempted.length === 2) throw Error('connection_lost_after_write');
  } }), /connection_lost_after_write/);
  const retried = [];
  await syncHistory({ database, upload: async object => { retried.push(object.key); await upload(object); } });
  assert.deepEqual(retried, [attempted[1]]);
  assert.equal(remote.size, 2);
  assert.deepEqual(JSON.parse(remote.get(attempted[0])), { reset_number: 2, reset_at_utc: '2031-11-18T20:00:00.123Z' });
  add.run(1, timestamp - 100);
  await syncHistory({ database, upload });
  assert.equal(remote.size, 3);
  await syncHistory({ database, upload: () => assert.fail('already acknowledged reset was uploaded again') });
});

test('archive scans reset history in bounded batches', async t => {
  const { database, add } = await fixture(t);
  for (let revision = 1; revision <= 25; revision++) add.run(revision, timestamp + revision);
  const uploaded = [];
  const upload = ({ body }) => uploaded.push(JSON.parse(body).reset_number);
  assert.equal(await syncHistory({ database, upload }), true);
  assert.equal(uploaded.length, 20);
  assert.equal(await syncHistory({ database, upload }), false);
  assert.deepEqual(uploaded, Array.from({ length: 25 }, (_, index) => index + 1));
});

test('S3 writes are conditional and an existing object is acknowledged only with the same checksum', async t => {
  const { directory } = await fixture(t);
  const body = 'private fixture body\n';
  const checksum = createHash('sha256').update(body).digest('base64');
  const object = { key: 'resets/0000000000000001.json', body };
  const requests = [];
  let existingChecksum = checksum;
  const upload = createS3Writer({ bucket: 'fixture-bucket', runtime: directory, run: async args => {
    requests.push(args);
    if (args.includes('put-object')) {
      assert.equal(await readFile(args[args.indexOf('--body') + 1], 'utf8'), body);
      assert.equal(args[args.indexOf('--if-none-match') + 1], '*');
      assert.equal(args[args.indexOf('--checksum-sha256') + 1], checksum);
      throw Object.assign(new Error('AWS CLI exited'), { stderr: '(PreconditionFailed) when calling the PutObject operation' });
    }
    return { ChecksumSHA256: existingChecksum };
  } });
  await upload(object);
  assert.equal(requests[1][1], 'head-object');
  assert.ok(requests[1].includes('--checksum-mode'));
  existingChecksum = 'different';
  await assert.rejects(upload(object), /s3_checksum_mismatch/);
  assert.ok((await readdir(directory)).every(name => name.startsWith('counter.sqlite')));
});
