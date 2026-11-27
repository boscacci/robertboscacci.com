import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { mkdtemp, readFile, readdir, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import test from 'node:test';

const baseURL = 'https://robertboscacci.com/';

function linkPaths(html) {
  return [...html.matchAll(/<a\s[^>]*?\bhref="([^"]+)"/g)]
    .map(([, href]) => new URL(href, baseURL))
    .filter(url => url.origin === new URL(baseURL).origin)
    .map(url => url.pathname);
}

test('the Tags menu and topic pages make every public post discoverable without listing family research', async () => {
  const output = await mkdtemp(join(tmpdir(), 'site-tags-'));
  try {
    execFileSync('hugo', ['--environment', 'production', '--baseURL', baseURL, '--destination', output], { stdio: 'pipe' });
    const read = path => readFile(join(output, path), 'utf8');
    const home = await read('index.html');
    assert.ok(linkPaths(home.match(/<nav\b[^>]*>[\s\S]*?<\/nav>/)[0]).includes('/tags/'), 'The main menu links to Tags');

    const topics = (await readdir(join(output, 'tags'), { withFileTypes: true })).filter(entry => entry.isDirectory());
    const directory = await read('tags/index.html');
    const directoryLinks = new Set(linkPaths(directory));
    const pathsByTopic = new Map();
    for (const topic of topics) {
      const topicPath = `/tags/${topic.name}/`;
      assert.ok(directoryLinks.has(topicPath), `${topicPath} is in the tag browser`);
      const entries = await readdir(join(output, topicPath), { recursive: true, withFileTypes: true });
      const pages = new Set();
      for (const entry of entries.filter(entry => entry.name === 'index.html')) {
        const html = await readFile(join(entry.parentPath, entry.name), 'utf8');
        for (const [heading] of html.matchAll(/<h3\b[^>]*>[\s\S]*?<\/h3>/g)) {
          for (const path of linkPaths(heading)) pages.add(path);
        }
      }
      assert.ok(pages.size, `${topicPath} has at least one post or page`);
      pathsByTopic.set(topicPath, pages);
    }
    assert.ok(pathsByTopic.get('/tags/backpacking/')?.has('/blog/2025/rainier-backpacking/'));
    assert.ok(pathsByTopic.get('/tags/computer-vision/')?.has('/book/'));
    assert.ok(pathsByTopic.get('/tags/computer-vision/')?.has('/projects/film_slate_detector/'));
    assert.ok(linkPaths(await read('projects/film_slate_detector/index.html')).includes('/tags/computer-vision/'));

    const sitemap = await read('sitemap.xml');
    const publicPages = [...sitemap.matchAll(/<loc>([^<]+)<\/loc>/g)]
      .map(([, url]) => new URL(url).pathname)
      .filter(path => path !== '/' && !path.startsWith('/tags/'));
    for (const path of publicPages) {
      const topics = [...pathsByTopic.values()].filter(pages => pages.has(path));
      assert.ok(topics.length >= 3 && topics.length <= 5, `${path} has ${topics.length} tags (expected 3–5)`);
    }

    for (const path of ['/enrique-pereira/', '/robert-boscacci-wwii/']) {
      const page = await read(`${path}index.html`);
      assert.match(page, /<meta name="robots" content="noindex/);
      assert.ok(![...pathsByTopic.values()].some(pages => pages.has(path)), `${path} stays out of topic listings`);
    }
  } finally { await rm(output, { recursive: true, force: true }); }
});
