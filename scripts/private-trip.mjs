import { execFileSync } from 'node:child_process';
import { createHash, randomBytes } from 'node:crypto';
import { mkdir, mkdtemp, readFile, rename, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { createRequire } from 'node:module';

export const parameter = '/robertboscacci-com/private-trips/password';
export const pagePath = 'private/family-2027/index.html';
const region = 'us-west-2';
const root = fileURLToPath(new URL('../', import.meta.url));
const require = createRequire(import.meta.url);

export async function decryptPage(encrypted, password) {
  const message = encrypted.match(/"staticryptEncryptedMsgUniqueVariableName":\s*"([^"]+)"/);
  const salt = encrypted.match(/"staticryptSaltUniqueVariableName":\s*"([^"]+)"/);
  if (!message || !salt) throw new Error('Invalid encrypted page.');
  const cryptoEngine = require('staticrypt/lib/cryptoEngine.js');
  const codec = require('staticrypt/lib/codec.js').init(cryptoEngine);
  const hashed = await cryptoEngine.hashPassword(password, salt[1]);
  const result = await codec.decode(message[1], hashed, salt[1]);
  if (!result.success) throw new Error('Cannot decrypt page.');
  return result.decoded;
}

export function readPassword() {
  if (process.env.STATICRYPT_PASSWORD) return process.env.STATICRYPT_PASSWORD;
  try {
    return execFileSync('aws', ['ssm', 'get-parameter', '--region', region, '--name', parameter,
      '--with-decryption', '--query', 'Parameter.Value', '--output', 'text'], { encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] }).trim();
  } catch { throw new Error('Cannot read trip password from AWS SSM; check authentication and access.'); }
}

export async function encryptPage(html, password, destination) {
  if (typeof password !== 'string' || password.length < 24) throw new Error('A unique password of at least 24 characters is required.');
  const temporary = await mkdtemp(join(tmpdir(), 'private-trip-'));
  try {
    const source = join(temporary, 'index.html');
    await writeFile(source, html, { mode: 0o600 });
    execFileSync(process.execPath, [join(root, 'node_modules/staticrypt/cli/index.js'), source,
      '--directory', join(temporary, 'encrypted'), '--config', 'false', '--remember', 'false',
      '--template-title', 'Family trip', '--template-button', 'Open trip plan',
      '--template-color-primary', '#235c4e', '--template-color-secondary', '#122c29',
      '--template-instructions', 'Enter the family password to open our trip plan.'], {
      env: { ...process.env, STATICRYPT_PASSWORD: password }, stdio: ['ignore', 'pipe', 'pipe'],
    });
    let encrypted = await readFile(join(temporary, 'encrypted/index.html'), 'utf8');
    const hashes = [...encrypted.matchAll(/<script>([\s\S]*?)<\/script>/g)]
      .map((match) => `'sha256-${createHash('sha256').update(match[1]).digest('base64')}'`).join(' ');
    encrypted = encrypted.replace('<html class=', '<html lang="en" class=')
      .replace('<head>', `<head><meta name="robots" content="noindex, nofollow, noarchive"><meta name="referrer" content="no-referrer"><meta http-equiv="Content-Security-Policy" content="default-src 'none'; script-src ${hashes}; style-src 'unsafe-inline'; img-src data:; form-action 'none'; base-uri 'none'">`)
      .replace('name="password"', 'name="password" aria-label="Family password" autocomplete="current-password" required')
      .replace('</style>', '.staticrypt-page{width:min(360px,100%)}.staticrypt-form{padding:28px}input:focus-visible{outline:2px solid #235c4e;outline-offset:3px}</style>');
    // Write atomically; an interrupted encryption must preserve the last good artifact.
    await mkdir(dirname(destination), { recursive: true });
    await writeFile(`${destination}.tmp`, encrypted);
    await rename(`${destination}.tmp`, destination);
  } finally { await rm(temporary, { recursive: true, force: true }); }
}

async function main() {
  const [command, source] = process.argv.slice(2);
  if (command === 'initialize-password') {
    // No overwrite: retrying setup cannot silently rotate a deployed page's password.
    const input = { Name: parameter, Type: 'SecureString',
      Value: randomBytes(24).toString('base64url'), Description: 'Family trip page encryption password', Overwrite: false };
    const { SSMClient, PutParameterCommand } = await import('@aws-sdk/client-ssm');
    const client = new SSMClient({ region });
    try {
      await client.send(new PutParameterCommand(input));
      console.log(JSON.stringify({ event: 'password_initialized', parameter }));
    } catch { throw new Error('Password setup failed or parameter already exists. Existing passwords are never overwritten.'); }
    finally { client.destroy(); }
  } else if (command === 'decrypt') {
    const html = await decryptPage(await readFile(join(root, 'static', pagePath), 'utf8'), readPassword());
    const output = join(root, 'data/private-trips/plan.html');
    await mkdir(dirname(output), { recursive: true });
    await writeFile(output, html, { mode: 0o600 });
    console.log(JSON.stringify({ event: 'trip_ready_to_edit', path: 'data/private-trips/plan.html' }));
  } else if (command === 'encrypt' && source) {
    await encryptPage(await readFile(resolve(source), 'utf8'), readPassword(), join(root, 'static', pagePath));
    console.log(JSON.stringify({ event: 'trip_encrypted', path: pagePath }));
  } else {
    throw new Error('Usage: node scripts/private-trip.mjs initialize-password | decrypt | encrypt <ignored-private-source.html>');
  }
}
if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  main().catch(() => { console.error('Private trip operation failed. Check inputs, AWS access, and dependencies; no secret details logged.'); process.exitCode = 1; });
}
