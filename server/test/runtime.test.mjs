import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { Miniflare, convertV4MiniflareOptions, Response as WorkerResponse } from 'miniflare';
import { hashToken } from '../src/worker.mjs';

test('real Workers runtime and D1 execute authenticated photo contract with mock Gemini', async () => {
  let calls = 0;
  let observed;
  const mf = new Miniflare(convertV4MiniflareOptions({ modules: [
    { type: 'ESModule', path: fileURLToPath(new URL('../src/entry.mjs', import.meta.url)) },
    { type: 'ESModule', path: fileURLToPath(new URL('../src/worker.mjs', import.meta.url)) },
  ],
    compatibilityDate: '2026-10-20',
    d1Databases: ['DB'],
    bindings: { GEMINI_API_KEY: 'test-only', GEMINI_MODEL: 'gemini-3.8-flash',
      USER_DAILY_LIMIT: '2', GLOBAL_DAILY_LIMIT: '3', GLOBAL_MINUTE_LIMIT: '3' },
    outboundService: async (request) => {
      calls++;
      observed = { url: request.url, key: request.headers.get('x-goog-api-key'), input: await request.json() };
      return WorkerResponse.json({ candidates: [{ finishReason: 'STOP', content: { parts: [
        { text: JSON.stringify({ items: [], warnings: ['Еды не видно.'] }) },
      ] } }] });
    },
  }));
  try {
    const db = await mf.getD1Database('DB');
    const sql = readFileSync(new URL('../migrations/0001.sql', import.meta.url), 'utf8');
    for (const statement of sql.split(';').filter(s => s.trim())) await db.prepare(statement).run();
    const token = 'a'.repeat(43);
    await db.prepare('INSERT INTO users(id, token_hash) VALUES (?, ?)')
      .bind('alice', await hashToken(token)).run();
    const send = (id, auth = token) => mf.dispatchFetch('https://fitlife.test/v1/analyze', {
      method: 'POST', headers: { Authorization: `Bearer ${auth}`,
        'Content-Type': 'image/jpeg', 'X-Request-Id': id },
      body: new Uint8Array([255, 216, 255, 224, 255, 217]),
    });
    assert.equal((await send('a'.repeat(32), 'b'.repeat(43))).status, 401);
    const result = await send('a'.repeat(32));
    assert.equal(result.status, 200, JSON.stringify({ response: await result.clone().json(), calls }));
    assert.equal(new URL(observed.url).hostname, 'generativelanguage.googleapis.com');
    assert.equal(observed.key, 'test-only');
    assert.equal(observed.input.contents[0].parts[0].inlineData.mimeType, 'image/jpeg');
    assert.deepEqual((await result.json()).items, []);
    assert.equal((await send('a'.repeat(32))).status, 429);
    const concurrent = await Promise.all(['b', 'c', 'd'].map(c => send(c.repeat(32))));
    assert.deepEqual(concurrent.map(r => r.status).sort(), [200, 429, 429]);
    assert.equal(calls, 2);
    await db.prepare('UPDATE users SET enabled = 0').run();
    assert.equal((await send('e'.repeat(32))).status, 401);
  } finally { await mf.dispose(); }
});
