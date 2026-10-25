import { execFileSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { mkdir, readFile, writeFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import { join } from 'node:path';
import { pagePath } from './private-trip.mjs';

const root = fileURLToPath(new URL('../', import.meta.url));
const bucket = 'robertboscacci-com-dev-site';
const distribution = 'E282I2XU6PLMW4';
const region = 'us-west-2';
const started = Date.now();
function run(command, args) {
  return execFileSync(command, args, { cwd: root, encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] }).trim();
}
try {
  if (run('git', ['status', '--porcelain'])) throw new Error('dirty_worktree');
  if (!['git@github.com:boscacci/robertboscacci.com.git', 'https://github.com/boscacci/robertboscacci.com.git'].includes(run('git', ['remote', 'get-url', 'origin']))) throw new Error('wrong_repository');
  const identity = JSON.parse(run('aws', ['sts', 'get-caller-identity']));
  if (identity.Account !== '062008221187') throw new Error('wrong_aws_account');
  const aliases = JSON.parse(run('aws', ['cloudfront', 'get-distribution', '--id', distribution,
    '--query', 'Distribution.DistributionConfig.Aliases.Items']));
  if (!aliases.includes('dev.robertboscacci.com')) throw new Error('wrong_distribution');
  const commit = run('git', ['rev-parse', 'HEAD']);
  const file = join(root, 'static', pagePath);
  const html = await readFile(file);
  const sha256 = createHash('sha256').update(html).digest('hex');
  if (!html.includes('staticryptEncryptedMsgUniqueVariableName') || html.includes('Little campers.')) throw new Error('unencrypted_artifact');
  // Tests run against this clean commit before any external write.
  run('node', ['--test', 'tests/private-trip.test.mjs']);
  run('node', ['tests/private-trip-browser.mjs']);
  run('npm', ['audit', '--audit-level=high']);
  const release = join(root, 'outputs/private-trip/releases', commit);
  await mkdir(release, { recursive: true });
  await writeFile(join(release, 'index.html'), html);
  // Only this page is deployed; unrelated dev content is preserved. No mutable build step.
  const result = JSON.parse(run('aws', ['s3api', 'put-object', '--region', region, '--bucket', bucket,
    '--key', pagePath, '--body', file, '--content-type', 'text/html; charset=utf-8', '--cache-control', 'no-store',
    '--metadata', `commit=${commit},sha256=${sha256}`, '--checksum-algorithm', 'SHA256']));
  run('aws', ['cloudfront', 'create-invalidation', '--distribution-id', distribution, '--paths', '/private/family-2027/*']);
  const url = 'https://dev.robertboscacci.com/private/family-2027/';
  // Bound propagation retries, and verify exactly the bytes that were version-controlled.
  let matched = false;
  for (let attempt = 0; attempt < 12; attempt++) {
    const response = await fetch(`${url}?release=${commit}`, { signal: AbortSignal.timeout(10000) });
    const bytes = Buffer.from(await response.arrayBuffer());
    if (response.ok && createHash('sha256').update(bytes).digest('hex') === sha256) { matched = true; break; }
    await new Promise((done) => setTimeout(done, 2000));
  }
  if (!matched) throw new Error('dev_artifact_mismatch');
  run('node', ['tests/private-trip-browser.mjs', url]);
  const record = { event: 'dev_trip_verified', commit, sha256, url, bucket, key: pagePath,
    versionId: result.VersionId ?? null, verifiedAt: new Date().toISOString(), durationMs: Date.now() - started };
  await writeFile(join(release, 'release.json'), JSON.stringify(record, null, 2));
  console.log(JSON.stringify(record));
} catch (error) {
  console.error(JSON.stringify({ event: 'dev_trip_failed', reason: /^[a-z_]+$/.test(error.message) ? error.message : 'command_or_smoke_failure',
    durationMs: Date.now() - started, action: 'Check AWS access and rerun local validation; never print passwords or enable traces.' }));
  process.exitCode = 1;
}
