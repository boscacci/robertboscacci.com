import { execFile } from 'node:child_process';
import { createHash } from 'node:crypto';
import { mkdtemp, rm, stat, writeFile } from 'node:fs/promises';
import { join, resolve } from 'node:path';
import { performance } from 'node:perf_hooks';
import { DatabaseSync } from 'node:sqlite';
import { fileURLToPath } from 'node:url';
import { promisify } from 'node:util';

const account = '062008221187';
const execute = promisify(execFile);
const batchSize = 20;

export async function syncHistory({ database, upload }) {
  if (!(await stat(database)).isFile()) throw Error('invalid_archive_database');
  const db = new DatabaseSync(database);
  try {
    db.exec(`PRAGMA busy_timeout = 3000;
      CREATE TABLE IF NOT EXISTS reset_history_archive (revision INTEGER PRIMARY KEY);`);
    const pending = db.prepare(`SELECT history.revision, history.reset_at
      FROM reset_history AS history LEFT JOIN reset_history_archive AS archive USING (revision)
      WHERE archive.revision IS NULL ORDER BY history.revision LIMIT ?`);
    const acknowledge = db.prepare('INSERT OR IGNORE INTO reset_history_archive VALUES (?)');
    for (const { revision, reset_at } of pending.all(batchSize)) {
      const key = `resets/${String(revision).padStart(16, '0')}.json`;
      const body = JSON.stringify({ reset_number: revision, reset_at_utc: new Date(reset_at).toISOString() }) + '\n';
      // Save the acknowledgment after S3 confirms the write. A retry checks the same object.
      await upload({ key, body });
      acknowledge.run(revision);
    }
    return Boolean(pending.get(1));
  } finally {
    db.close();
  }
}

export function createS3Writer({ bucket, runtime, run }) {
  return async ({ key, body }) => {
    const checksum = createHash('sha256').update(body).digest('base64');
    const directory = await mkdtemp(join(runtime, 'upload-'));
    const file = join(directory, 'reset.json');
    const target = ['--bucket', bucket, '--key', key, '--expected-bucket-owner', account, '--region', 'us-west-2'];
    try {
      await writeFile(file, body, { mode: 0o600 });
      let result;
      try {
        result = await run(['s3api', 'put-object', ...target, '--body', file, '--content-type', 'application/json',
          '--server-side-encryption', 'AES256', '--if-none-match', '*', '--checksum-sha256', checksum]);
      } catch (error) {
        if (!/\((?:PreconditionFailed|412)\) when calling the PutObject operation/.test(error.stderr)) throw Error('s3_write_failed');
        try { result = await run(['s3api', 'head-object', ...target, '--checksum-mode', 'ENABLED']); }
        catch { throw Error('s3_verification_failed'); }
      }
      if (result.ChecksumSHA256 !== checksum) throw Error('s3_checksum_mismatch');
    } finally {
      await rm(directory, { recursive: true, force: true });
    }
  };
}

async function aws(args, credentials = {}) {
  const { stdout } = await execute('aws', [...args, '--output', 'json', '--no-cli-pager',
    '--cli-connect-timeout', '4', '--cli-read-timeout', '5'], {
    env: { ...process.env, ...credentials, AWS_MAX_ATTEMPTS: '1', AWS_IGNORE_CONFIGURED_ENDPOINT_URLS: 'true' },
    maxBuffer: 64 * 1024, timeout: 12_000,
  });
  return JSON.parse(stdout || '{}');
}

async function runArchive(environment, database, runtime) {
  if (!['dev', 'production'].includes(environment) || !database || !runtime) throw Error('invalid_archive_configuration');
  const prefix = `robertboscacci-howlong-archive-${environment}`;
  let credentials;
  try {
    const { Credentials } = await aws(['sts', 'assume-role', '--role-arn', `arn:aws:iam::${account}:role/${prefix}`,
      '--role-session-name', `howlong-archive-${environment}`, '--duration-seconds', '900', '--region', 'us-west-2']);
    if (!Credentials?.AccessKeyId || !Credentials.SecretAccessKey || !Credentials.SessionToken) throw Error('invalid_session');
    credentials = { AWS_ACCESS_KEY_ID: Credentials.AccessKeyId, AWS_SECRET_ACCESS_KEY: Credentials.SecretAccessKey, AWS_SESSION_TOKEN: Credentials.SessionToken };
  } catch { throw Error('archive_role_unavailable'); }
  const run = args => aws(args, credentials);
  const pending = await syncHistory({ database, upload: createS3Writer({ bucket: `${prefix}-${account}`, runtime, run }) });
  try {
    await run(['cloudwatch', 'put-metric-data', '--region', 'us-east-1', '--namespace', `HowLong/Archive/${environment}`,
      '--metric-data', 'MetricName=Heartbeat,Value=1,Unit=Count']);
  } catch { throw Error('archive_heartbeat_failed'); }
  return pending;
}

if (process.argv[1] && fileURLToPath(import.meta.url) === resolve(process.argv[1])) {
  const [, , environment, database, runtime] = process.argv;
  const started = performance.now();
  try {
    const pending = await runArchive(environment, database, runtime);
    console.log(JSON.stringify({ event: 'howlong_archive_sync', environment, pending, durationMs: Math.round(performance.now() - started) }));
  } catch (error) {
    console.error(JSON.stringify({ event: 'howlong_archive_failed', reason: /^[a-z_]+$/.test(error.message) ? error.message : 'archive_runtime_error',
      action: 'Check archive IAM, S3 availability, and local SQLite health; the next timer run retries pending records.' }));
    process.exitCode = 1;
  }
}
