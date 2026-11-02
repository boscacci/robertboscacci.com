import { execFileSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { readFile, writeFile } from 'node:fs/promises';
import { join } from 'node:path';
import { validateRelease } from './site-release.mjs';

function run(command, args) {
  return execFileSync(command, args, { encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] }).trim();
}
try {
  const [tag, approvalFile] = process.argv.slice(2);
  if (!/^v(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$/.test(tag ?? '')) throw Error('invalid_release_tag');
  if (run('git', ['status', '--porcelain'])) throw Error('dirty_worktree');
  run('git', ['fetch', 'origin', 'main', '--tags']);
  const commit = run('git', ['rev-parse', 'HEAD']);
  if (commit !== run('git', ['rev-parse', 'origin/main'])) throw Error('not_default_branch_commit');
  const directory = join('outputs/site-releases', `${commit}-production`);
  const file = join(directory, 'release.json');
  const record = JSON.parse(await readFile(file, 'utf8'));
  const approval = JSON.parse(await readFile(approvalFile, 'utf8'));
  Object.assign(record, { tag, approval });
  validateRelease(record, tag, record.sha256, commit);
  // Only an absent tag may be created; an existing tag must identify the exact approved commit.
  const existing = run('git', ['tag', '--list', tag]);
  if (existing) {
    if (run('git', ['rev-parse', `${tag}^{commit}`]) !== commit) throw Error('immutable_tag_conflict');
  } else run('git', ['tag', '-a', tag, '-m', `Release ${tag}: ${commit}; artifact SHA-256 ${record.sha256}`]);
  run('git', ['push', 'origin', `refs/tags/${tag}`]);
  await writeFile(file, JSON.stringify(record, null, 2) + '\n');
  run('node', ['scripts/site-release.mjs', tag, record.sha256, directory]);
  let published;
  try { published = JSON.parse(run('gh', ['release', 'view', tag, '--json', 'tagName'])); }
  catch (error) { if (!error.stderr?.toString().includes('release not found')) throw error; }
  if (!published) {
    const notes = join(directory, 'notes.md');
    await writeFile(notes, `Promotes the production artifact tested on dev.\n\nCommit: ${commit}\n\nSHA-256: ${record.sha256}\n\nProduction approval: ${approval.instruction}\n\nApproved target: ${approval.target}\n\nApproval recorded: ${approval.recordedAt}\n\nSee release.json for dev verification.\n`);
    run('gh', ['release', 'create', tag, '--verify-tag', '--title', `${tag}: site-wide Google Analytics`, '--notes-file', notes, join(directory, 'site.tar.gz'), file]);
  }
  // Verify published bytes before requesting promotion; retrying never replaces release assets.
  const remote = JSON.parse(run('gh', ['api', `repos/boscacci/robertboscacci.com/releases/tags/${tag}`]));
  if (!remote.assets.some(asset => asset.name === 'site.tar.gz') || !remote.assets.some(asset => asset.name === 'release.json')) throw Error('missing_release_assets');
  const remoteBytes = execFileSync('gh', ['release', 'download', tag, '--pattern', 'site.tar.gz', '--output', '-'], { maxBuffer: 32 * 1024 * 1024, stdio: ['ignore', 'pipe', 'pipe'] });
  if (createHash('sha256').update(remoteBytes).digest('hex') !== record.sha256) throw Error('published_artifact_mismatch');
  const remoteRecord = JSON.parse(run('gh', ['release', 'download', tag, '--pattern', 'release.json', '--output', '-']));
  validateRelease(remoteRecord, tag, record.sha256, commit);
  run('gh', ['workflow', 'run', 'gh-pages.yml', '--ref', 'main', '-f', `release_tag=${tag}`, '-f', `sha256=${record.sha256}`]);
  console.log(JSON.stringify({ event: 'production_promotion_requested', tag, commit, sha256: record.sha256 }));
} catch (error) {
  console.error(JSON.stringify({ event: 'production_promotion_failed', reason: /^[a-z_]+$/.test(error.message) ? error.message : 'release_command_failed', action: 'Inspect release assets and approval; retry without moving tags or rebuilding.' }));
  process.exitCode = 1;
}
