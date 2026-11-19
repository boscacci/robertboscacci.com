import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
import test from 'node:test';
import { fileURLToPath } from 'node:url';

const policy = fileURLToPath(new URL('../scripts/howlong-scan.jq', import.meta.url));

test('the cloud systemd service leaves the private socket directory owned by the container user', () => {
  const installer = readFileSync(new URL('../services/howlong/cloud-install.sh', import.meta.url), 'utf8');
  const service = installer.split('cat > /etc/systemd/system/howlong-cloud.service <<EOF\n')[1].split('\nEOF')[0];
  assert.doesNotMatch(service, /^RuntimeDirectory=/m);
  assert.match(service, /^ExecStartPre=\/usr\/bin\/install -d -o 1000 -g 1000 -m 0700 \/run\/howlong$/m);
  assert.match(service, /^ExecStopPost=\/usr\/bin\/rm -f \/run\/howlong\/server.sock$/m);
});

test('a complete ECR scan with empty severity counts passes the release check', () => {
  const scans = [
    [{ imageScanStatus: { status: 'COMPLETE' }, imageScanFindings: { findingSeverityCounts: {} } }, true],
    [{ imageScanStatus: { status: 'IN_PROGRESS' } }, false],
    [{ imageScanStatus: { status: 'COMPLETE' }, imageScanFindings: { findingSeverityCounts: { HIGH: 1 } } }, false],
  ];
  for (const [scan, expected] of scans) {
    const result = spawnSync('jq', ['-ef', policy], { input: JSON.stringify(scan), encoding: 'utf8' });
    assert.ifError(result.error);
    assert.equal(result.stdout.trim(), String(expected));
    assert.equal(result.status, expected ? 0 : 1);
  }
});
