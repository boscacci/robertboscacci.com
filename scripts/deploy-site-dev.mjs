import { execFileSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { mkdir, mkdtemp, readFile, readdir, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { smoke } from '../tests/site-dev-browser.mjs';

const bucket = 'robertboscacci-com-dev-site';
const distribution = 'E282I2XU6PLMW4';
const region = 'us-west-2';
const baseURL = 'https://dev.robertboscacci.com/';
const started = Date.now();
const productionArtifact = process.argv.includes('--production-artifact');
function run(command, args) {
  return execFileSync(command, args, { encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] }).trim();
}
let temporary;
let release;
let verified = false;
async function verifyFiles(source, target) {
  for (const entry of await readdir(source, { withFileTypes: true })) {
    if (entry.name === 'private') continue;
    const original = join(source, entry.name);
    const uploaded = join(target, entry.name);
    if (entry.isDirectory()) await verifyFiles(original, uploaded);
    else if (!(await readFile(original)).equals(await readFile(uploaded))) throw Error('uploaded_artifact_mismatch');
  }
}
try {
  if (run('git', ['status', '--porcelain'])) throw Error('dirty_worktree');
  if (!['git@github.com:boscacci/robertboscacci.com.git', 'https://github.com/boscacci/robertboscacci.com'].includes(run('git', ['remote', 'get-url', 'origin']))) throw Error('wrong_repository');
  if (JSON.parse(run('aws', ['sts', 'get-caller-identity'])).Account !== '062008221187') throw Error('wrong_account');
  const aliases = JSON.parse(run('aws', ['cloudfront', 'get-distribution', '--id', distribution,
    '--query', 'Distribution.DistributionConfig.Aliases.Items']));
  if (!aliases.includes('dev.robertboscacci.com')) throw Error('wrong_distribution');
  const tags = JSON.parse(run('aws', ['s3api', 'get-bucket-tagging', '--bucket', bucket])).TagSet;
  if (!tags.some(tag => tag.Key === 'Environment' && tag.Value === 'development')) throw Error('wrong_bucket');
  for (const args of [['test'], ['run', 'test:hub'], ['run', 'test:analytics'], ['audit', '--audit-level=high']]) run('npm', args);
  const commit = run('git', ['rev-parse', 'HEAD']);
  const candidate = join('outputs/site-releases', commit + (productionArtifact ? '-production' : ''));
  // Refuse to replace an existing immutable artifact; retries rebuild only failed attempts.
  await mkdir(candidate, { recursive: false }).catch(async error => {
    if (error.code !== 'ENOENT') throw error;
    await mkdir('outputs/site-releases', { recursive: true });
    await mkdir(candidate);
  });
  release = candidate;
  temporary = await mkdtemp(join(tmpdir(), 'site-dev-'));
  const site = join(temporary, 'site');
  run('hugo', ['--environment', productionArtifact ? 'production' : 'development', '--baseURL', productionArtifact ? 'https://robertboscacci.com/' : baseURL, '--destination', site, '--minify']);
  if (!productionArtifact) await rm(join(site, 'CNAME'), { force: true });
  // Preserve the encrypted pages' independent deployment workflow.
  if (!productionArtifact) await rm(join(site, 'private'), { recursive: true, force: true });
  const archive = join(release, 'site.tar.gz');
  run('tar', ['-czf', archive, '-C', site, '.']);
  const sha256 = createHash('sha256').update(await readFile(archive)).digest('hex');
  run('aws', ['s3', 'sync', site, `s3://${bucket}/`, '--region', region,
    '--exclude', 'private/*', '--cache-control', 'public,max-age=300', '--metadata', `commit=${commit},artifact=${sha256}`]);
  // Verify every delivered byte via S3, without logging page contents.
  const downloaded = join(temporary, 'downloaded');
  run('aws', ['s3', 'sync', `s3://${bucket}/`, downloaded, '--region', region, '--exclude', 'private/*']);
  await verifyFiles(site, downloaded);
  run('aws', ['cloudfront', 'create-invalidation', '--distribution-id', distribution, '--paths', '/*']);
  const expected = createHash('sha256').update(await readFile(join(site, 'index.html'))).digest('hex');
  let matched = false;
  for (let attempt = 0; attempt < 15; attempt++) {
    const response = await fetch(`${baseURL}?release=${commit}`, { signal: AbortSignal.timeout(10000) });
    if (response.ok && createHash('sha256').update(Buffer.from(await response.arrayBuffer())).digest('hex') === expected) { matched = true; break; }
    await new Promise(done => setTimeout(done, 2000));
  }
  if (!matched) throw Error('dev_artifact_mismatch');
  const measurementID = productionArtifact ? (await readFile('config/_default/config.toml', 'utf8')).match(/id = "(G-[A-Z0-9]+)"/)[1] : null;
  await smoke(baseURL, commit, measurementID);
  const record = { event: 'site_dev_verified', commit, sha256, baseURL, bucket, distribution,
    artifactEnvironment: productionArtifact ? 'production' : 'development',
    hugo: run('hugo', ['version']), verifiedAt: new Date().toISOString(), durationMs: Date.now() - started };
  await writeFile(join(release, 'release.json'), JSON.stringify(record, null, 2) + '\n');
  verified = true;
  console.log(JSON.stringify(record));
} catch (error) {
  console.error(JSON.stringify({ event: 'site_dev_failed', reason: /^[a-z_]+$/.test(error.message) ? error.message : 'validation_or_deployment_failure',
    durationMs: Date.now() - started, action: 'Inspect validation and dev infrastructure; rerun the same commit. Production was not deployed.' }));
  process.exitCode = 1;
} finally {
  if (temporary) await rm(temporary, { recursive: true, force: true });
  if (release && !verified) await rm(release, { recursive: true, force: true });
}
