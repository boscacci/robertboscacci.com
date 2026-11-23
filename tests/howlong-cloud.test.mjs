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

test('an owner-confirmed smoke test after dev deployment survives a later automated recheck', () => {
  const filter = fileURLToPath(new URL('../scripts/howlong-approval.jq', import.meta.url));
  const deployed = '2020-11-20T16:00:00Z';
  const verified = '2020-11-22T19:00:00Z';
  for (const [approvalTime, attestation, expected] of [
    ['2020-11-20T15:00:00Z', 'confirmed by owner', false],
    ['2020-11-21T17:00:00Z', '', false],
    ['2020-11-21T17:00:00Z', 'confirmed by owner', true],
    ['2020-11-22T20:00:00Z', '', true],
  ]) {
    const result = spawnSync('jq', ['-ef', filter, '--arg', 'host', 'tracker.test', '--arg', 'commit', 'abc',
      '--arg', 'digest', 'digest', '--arg', 'deployed', deployed, '--arg', 'verified', verified], {
      input: JSON.stringify({ target: 'tracker.test', commit: 'abc', artifact: 'digest',
        instruction: 'Promote to prod', recordedAt: approvalTime, humanSmokeTest: attestation }),
    });
    assert.equal(result.status, expected ? 0 : 1);
  }
});
