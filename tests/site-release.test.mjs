import test from 'node:test';
import assert from 'node:assert/strict';
import { validateRelease } from '../scripts/site-release.mjs';
const sha256 = 'a'.repeat(64);
const commit = 'b'.repeat(40);
const record = { tag: 'v1.0.1', commit, sha256, event: 'site_dev_verified', artifactEnvironment: 'production', approval: { target: 'production', instruction: 'Promote to prod, please.', recordedAt: '2026-11-02T00:00:00Z' } };
test('promotion requires the dev-tested production artifact and recorded release approval', () => {
  assert.doesNotThrow(() => validateRelease(record, 'v1.0.1', sha256, commit));
  for (const changed of [{sha256:'c'.repeat(64)}, {commit:'d'.repeat(40)}, {tag:'v1.0.2'}, {event:'failed'}, {artifactEnvironment:'development'}, {approval:null}, {approval:{target:'dev',instruction:'ok'}}]) {
    assert.throws(() => validateRelease({...record,...changed}, 'v1.0.1', sha256, commit));
  }
  for (const tag of ['main','v1.0.1;whoami','../v1.0.1','v01.0.1']) assert.throws(() => validateRelease(record, tag, sha256, commit));
});

import { execFileSync, spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { mkdtemp, writeFile, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
test('release verifier rejects tampered bytes, lightweight tags and commits outside main', async () => {
  const directory = await mkdtemp(join(tmpdir(), 'site-release-test-'));
  const script = resolve('scripts/site-release.mjs');
  const git = args => execFileSync('git', args, {cwd:directory,encoding:'utf8',stdio:['ignore','pipe','pipe']}).trim();
  try {
    git(['init','-b','main']);
    git(['config','user.name','Release Test']);git(['config','user.email','release-test@example.invalid']);
    git(['commit','--allow-empty','-m','fixture']);
    const commit = git(['rev-parse','HEAD']);
    git(['update-ref','refs/remotes/origin/main',commit]);
    git(['tag','-a','v1.0.1','-m','fixture']);
    const bytes = Buffer.from('immutable fixture archive');
    const sha256 = createHash('sha256').update(bytes).digest('hex');
    await writeFile(join(directory,'site.tar.gz'),bytes);
    await writeFile(join(directory,'release.json'),JSON.stringify({...record,commit,sha256}));
    const verify = () => spawnSync(process.execPath,[script,'v1.0.1',sha256,directory],{cwd:directory,encoding:'utf8'}).status;
    assert.equal(verify(),0);
    await writeFile(join(directory,'site.tar.gz'),'tampered');
    assert.equal(verify(),1);
    await writeFile(join(directory,'site.tar.gz'),bytes);
    git(['tag','-d','v1.0.1']);git(['tag','v1.0.1']);
    assert.equal(verify(),1);
    git(['tag','-d','v1.0.1']);git(['tag','-a','v1.0.1','-m','fixture']);
    git(['checkout','--orphan','other']);git(['commit','--allow-empty','-m','unrelated']);
    git(['update-ref','refs/remotes/origin/main',git(['rev-parse','HEAD'])]);
    assert.equal(verify(),1);
  } finally { await rm(directory,{recursive:true,force:true}); }
});
