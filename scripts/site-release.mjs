import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { readFile } from 'node:fs/promises';
import { execFileSync } from 'node:child_process';
import { pathToFileURL } from 'node:url';

export function validateRelease(record, tag, sha256, commit) {
  assert.match(tag, /^v(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$/);
  assert.match(sha256, /^[a-f0-9]{64}$/);
  assert.match(commit, /^[a-f0-9]{40}$/);
  assert.equal(record.tag, tag);
  assert.equal(record.commit, commit);
  assert.equal(record.sha256, sha256);
  assert.equal(record.event, 'site_dev_verified');
  assert.equal(record.artifactEnvironment, 'production');
  assert.equal(record.approval?.target, 'production');
  assert.ok(record.approval?.instruction?.trim());
  assert.ok(Number.isFinite(Date.parse(record.approval?.recordedAt)));
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  try {
    const [tag, expectedHash, directory] = process.argv.slice(2);
    const record = JSON.parse(await readFile(`${directory}/release.json`, 'utf8'));
    assert.equal(execFileSync('git', ['cat-file', '-t', tag], { encoding: 'utf8' }).trim(), 'tag');
    const commit = execFileSync('git', ['rev-parse', `${tag}^{commit}`], { encoding: 'utf8' }).trim();
    validateRelease(record, tag, expectedHash, commit);
    const hash = createHash('sha256').update(await readFile(`${directory}/site.tar.gz`)).digest('hex');
    assert.equal(hash, expectedHash);
    execFileSync('git', ['merge-base', '--is-ancestor', commit, 'origin/main']);
    console.log(JSON.stringify({ event: 'approved_release_verified', tag, commit, sha256: hash }));
  } catch {
    console.error(JSON.stringify({ event: 'release_verification_failed', action: 'Check the tag, immutable artifact checksum, dev result and recorded production approval. Do not rebuild.' }));
    process.exitCode = 1;
  }
}
