import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import test from 'node:test';
import { fileURLToPath } from 'node:url';

const policy = fileURLToPath(new URL('../scripts/howlong-scan.jq', import.meta.url));

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
