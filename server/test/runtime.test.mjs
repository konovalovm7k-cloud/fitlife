import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { Miniflare, convertV4MiniflareOptions, Response as WorkerResponse } from 'miniflare';
import { hashToken, identificationSchema, chefSchema } from '../src/worker.mjs';
import { chefCatalogue, chefCatalogueVersion } from '../src/chef_catalogue.mjs';

test('real Workers runtime and D1 execute authenticated photo contract with mock Gemini', async () => {
  let calls = 0;
  let observed;
  const mf = new Miniflare(convertV4MiniflareOptions({ modules: [
    { type: 'ESModule', path: fileURLToPath(new URL('../src/entry.mjs', import.meta.url)) },
    { type: 'ESModule', path: fileURLToPath(new URL('../src/worker.mjs', import.meta.url)) },
    { type: 'ESModule', path: fileURLToPath(new URL('../src/chef_catalogue.mjs', import.meta.url)) },
  ],
    compatibilityDate: '2026-10-20',
    d1Databases: ['DB'],
    bindings: { GEMINI_API_KEY: 'test-only', GEMINI_MODEL: 'gemini-3.5-flash-lite',
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

test('real Workers Chef returns only curated IDs and shares the atomic text quota', async () => {
  let calls = 0;
  const id = chefCatalogue[0].recordId;
  const mf = new Miniflare(convertV4MiniflareOptions({ modules: [
    { type: 'ESModule', path: fileURLToPath(new URL('../src/entry.mjs', import.meta.url)) },
    { type: 'ESModule', path: fileURLToPath(new URL('../src/worker.mjs', import.meta.url)) },
    { type: 'ESModule', path: fileURLToPath(new URL('../src/chef_catalogue.mjs', import.meta.url)) },
  ], compatibilityDate: '2026-10-20', d1Databases: ['DB'],
    bindings: { GEMINI_API_KEY: 'test-only', GEMINI_MODEL: 'gemini-3.5-flash-lite', USER_DAILY_LIMIT: '1' },
    outboundService: async (request) => {
      calls++;
      const input = await request.json();
      assert.deepEqual(input.generationConfig.responseSchema, chefSchema);
      assert.equal(input.generationConfig.maxOutputTokens, 1024);
      return WorkerResponse.json({ candidates: [{ finishReason: 'STOP', content: { parts: [{
        text: JSON.stringify({ items: [{ recordId: id, grams: 150.5, kcal: 999, source: 'fake' }],
          warnings: ['check_portions'], title: '100 kcal', satietyHours: 8 }),
      }] } }] });
    },
  }));
  try {
    const db = await mf.getD1Database('DB');
    const sql = readFileSync(new URL('../migrations/0001.sql', import.meta.url), 'utf8');
    for (const statement of sql.split(';').filter(s => s.trim())) await db.prepare(statement).run();
    const token = 'a'.repeat(43);
    await db.prepare('INSERT INTO users(id, token_hash) VALUES (?, ?)').bind('alice', await hashToken(token)).run();
    const send = (path, requestId) => mf.dispatchFetch(`https://fitlife.test${path}`, {
      method: 'POST', headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json', 'X-Request-Id': requestId },
      body: JSON.stringify({ text: 'Яблоко' }),
    });
    const response = await send('/v2/chef', 'a'.repeat(32));
    assert.equal(response.status, 200);
    assert.deepEqual(await response.json(), { version: 1, kind: 'chef', catalogueVersion: chefCatalogueVersion,
      requestId: 'a'.repeat(32), items: [{ recordId: id, grams: 150.5 }], warnings: ['check_portions'] });
    assert.equal((await send('/v2/identify-text', 'b'.repeat(32))).status, 429);
    assert.equal((await send('/v2/chef', 'c'.repeat(32))).status, 429);
    assert.equal(calls, 1);
    assert.equal((await db.prepare('SELECT COUNT(*) AS n FROM requests').first()).n, 1);
    await db.prepare('UPDATE users SET enabled = 0').run();
    assert.equal((await send('/v2/chef', 'd'.repeat(32))).status, 401);
  } finally { await mf.dispose(); }
});

test('real Workers runtime validates UTF-8 descriptions and shares quota with photos', async () => {
  let calls = 0;
  const mf = new Miniflare(convertV4MiniflareOptions({ modules: [
    { type: 'ESModule', path: fileURLToPath(new URL('../src/entry.mjs', import.meta.url)) },
    { type: 'ESModule', path: fileURLToPath(new URL('../src/worker.mjs', import.meta.url)) },
    { type: 'ESModule', path: fileURLToPath(new URL('../src/chef_catalogue.mjs', import.meta.url)) },
  ], compatibilityDate: '2026-10-20', d1Databases: ['DB'],
    bindings: { GEMINI_API_KEY: 'test-only', GEMINI_MODEL: 'gemini-3.5-flash-lite', USER_DAILY_LIMIT: '1' },
    outboundService: async (request) => {
      calls++;
      const input = await request.json();
      assert.deepEqual(input.contents[0].parts, [{ text: 'Яблоко 180 г' }]);
      return WorkerResponse.json({ candidates: [{ finishReason: 'STOP', content: { parts: [
        { text: JSON.stringify({ items: [], warnings: ['Тестовый ответ.'] }) },
      ] } }] });
    },
  }));
  try {
    const db = await mf.getD1Database('DB');
    const sql = readFileSync(new URL('../migrations/0001.sql', import.meta.url), 'utf8');
    for (const statement of sql.split(';').filter(s => s.trim())) await db.prepare(statement).run();
    const token = 'a'.repeat(43);
    await db.prepare('INSERT INTO users(id, token_hash) VALUES (?, ?)').bind('alice', await hashToken(token)).run();
    const send = (text, id) => mf.dispatchFetch('https://fitlife.test/v1/analyze-text', {
      method: 'POST', headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json', 'X-Request-Id': id },
      body: JSON.stringify({ text }),
    });
    assert.equal((await send('', 'a'.repeat(32))).status, 400);
    assert.equal((await send('Яблоко 180 г', 'a'.repeat(32))).status, 200);
    const photo = await mf.dispatchFetch('https://fitlife.test/v1/analyze', { method: 'POST',
      headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'image/jpeg', 'X-Request-Id': 'b'.repeat(32) },
      body: new Uint8Array([255, 216, 255, 224, 255, 217]),
    });
    assert.equal(photo.status, 429);
    assert.equal(calls, 1);
  } finally { await mf.dispose(); }
});

test('real Workers V2 excludes model nutrition and shares atomic D1 limits with V1', async () => {
  let calls = 0;
  const mf = new Miniflare(convertV4MiniflareOptions({ modules: [
    { type: 'ESModule', path: fileURLToPath(new URL('../src/entry.mjs', import.meta.url)) },
    { type: 'ESModule', path: fileURLToPath(new URL('../src/worker.mjs', import.meta.url)) },
    { type: 'ESModule', path: fileURLToPath(new URL('../src/chef_catalogue.mjs', import.meta.url)) },
  ], compatibilityDate: '2026-10-20', d1Databases: ['DB'],
    bindings: { GEMINI_API_KEY: 'test-only', GEMINI_MODEL: 'gemini-3.5-flash-lite', USER_DAILY_LIMIT: '2' },
    outboundService: async (request) => {
      calls++;
      const input = await request.json();
      assert.deepEqual(input.generationConfig.responseSchema, identificationSchema);
      return WorkerResponse.json({ candidates: [{ finishReason: 'STOP', content: { parts: [
        { text: JSON.stringify({ items: [{ name: 'Яблоко', grams: 180, confidence: 'high',
          kcal: 999, protein: 99, sourceId: 'invented' }], warnings: ['uncertain_portion'] }) },
      ] } }] });
    },
  }));
  try {
    const db = await mf.getD1Database('DB');
    for (const statement of readFileSync(new URL('../migrations/0001.sql', import.meta.url), 'utf8')
      .split(';').filter(s => s.trim())) await db.prepare(statement).run();
    const token = 'a'.repeat(43);
    await db.prepare('INSERT INTO users(id, token_hash) VALUES (?, ?)').bind('alice', await hashToken(token)).run();
    const send = (path, id) => mf.dispatchFetch(`https://fitlife.test${path}`, {
      method: 'POST', headers: { Authorization: `Bearer ${token}`,
        'Content-Type': path.endsWith('-text') ? 'application/json' : 'image/jpeg', 'X-Request-Id': id },
      body: path.endsWith('-text') ? JSON.stringify({ text: 'Яблоко 180 г' })
        : new Uint8Array([255, 216, 255, 224, 255, 217]),
    });
    for (const [path, id] of [['/v2/identify', 'a'], ['/v2/identify-text', 'b']]) {
      const result = await send(path, id.repeat(32));
      assert.equal(result.status, 200);
      assert.deepEqual(await result.json(), { version: 2, requestId: id.repeat(32),
        items: [{ name: 'Яблоко', grams: 180, confidence: 'high' }], warnings: ['uncertain_portion'] });
    }
    assert.equal((await send('/v2/identify-text', 'a'.repeat(32))).status, 429);
    assert.equal((await send('/v1/analyze', 'c'.repeat(32))).status, 429);
    assert.equal(calls, 2);
  } finally { await mf.dispose(); }
});
