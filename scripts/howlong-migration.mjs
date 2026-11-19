import { createHash } from 'node:crypto';
import { backup, DatabaseSync } from 'node:sqlite';
import { fileURLToPath } from 'node:url';

export function counterFingerprint(path) {
  const db = new DatabaseSync(path, { readOnly: true });
  try {
    db.exec('BEGIN');
    if (db.prepare('PRAGMA quick_check').get().quick_check !== 'ok') throw Error('Counter integrity check failed');
    const rows = db.prepare('SELECT id, start, revision FROM counter ORDER BY id').all();
    const [counter] = rows;
    if (rows.length !== 1 || counter.id !== 1 || !/^\d{4}-\d{2}-\d{2}$/.test(counter.start)
      || !Number.isSafeInteger(counter.revision) || counter.revision < 0) throw Error('Invalid counter state');
    const hash = createHash('sha256').update(JSON.stringify(counter));
    if (db.prepare("SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = 'reset_history'").get()) {
      for (const row of db.prepare('SELECT revision, reset_at FROM reset_history ORDER BY revision').iterate()) {
        hash.update('\n').update(JSON.stringify(row));
      }
    }
    return hash.digest('hex');
  } finally {
    db.close();
  }
}

export async function snapshotCounter(source, target) {
  const db = new DatabaseSync(source, { readOnly: true });
  try {
    await backup(db, target);
  } finally {
    db.close();
  }
  return counterFingerprint(target);
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  const [, , source, target] = process.argv;
  console.log(target ? await snapshotCounter(source, target) : counterFingerprint(source));
}
