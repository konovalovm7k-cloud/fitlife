import { test } from 'node:test';
import assert from 'node:assert/strict';
import { DatabaseSync } from 'node:sqlite';
import { readFileSync } from 'node:fs';
import { handle, hashToken, reserve, validateResult, MAX_IMAGE_BYTES } from '../src/worker.mjs';

const token = 'a'.repeat(43);
const food = { name: 'Рис варёный', grams: 150, kcal: 130, protein: 2.7,
  fat: 0.3, carbs: 28, fiber: 0.4, confidence: 'medium' };
const meal = { items: [food], warnings: ['Уточните масло.'] };
const jpeg = new Uint8Array([255, 216, 255, 224, 0, 255, 217]);
function request({ auth = `Bearer ${token}`, id = 'a'.repeat(32),
  body = jpeg, type = 'image/jpeg', method = 'POST' } = {}) {
  return new Request('https://fitlife.test/v1/analyze', { method,
    headers: { Authorization: auth, 'X-Request-Id': id, 'Content-Type': type }, body });
}
class SqliteD1 {
  constructor() {
    this.db = new DatabaseSync(':memory:');
    this.db.exec(readFileSync(new URL('../migrations/0001.sql', import.meta.url), 'utf8'));
  }
  prepare(sql) {
    const statement = this.db.prepare(sql);
    return { bind: (...values) => ({
      first: async () => statement.get(...values) ?? null,
      run: async () => ({ meta: { changes: Number(statement.run(...values).changes) } }),
    }) };
  }
}
async function setup() {
  const DB = new SqliteD1();
  DB.db.prepare('INSERT INTO users(id, token_hash) VALUES (?, ?)').run('alice', await hashToken(token));
  return { DB, GEMINI_API_KEY: 'test-secret', GEMINI_MODEL: 'gemini-3.8-flash' };
}
function provider(result = meal, status = 200) {
  return async () => Response.json({ candidates: [{ finishReason: 'STOP',
    content: { parts: [{ text: JSON.stringify(result) }] } }] }, { status });
}
test('authenticated photo reaches Gemini with schema and returns validated estimate', async () => {
  const env = await setup();
  let calls = 0;
  const response = await handle(request(), env, async (url, options) => {
    calls++;
    assert.equal(url, 'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.8-flash:generateContent');
    assert.equal(options.headers['x-goog-api-key'], 'test-secret');
    assert.equal(options.redirect, 'manual');
    const body = JSON.parse(options.body);
    assert.equal(body.contents[0].parts[0].inlineData.mimeType, 'image/jpeg');
    assert.equal(body.generationConfig.responseMimeType, 'application/json');
    assert.ok(body.generationConfig.responseSchema.properties.items);
    return provider()();
  });
  assert.equal(response.status, 200);
  assert.deepEqual(await response.json(), { version: 1, requestId: 'a'.repeat(32), ...meal });
  assert.equal(calls, 1);
  assert.equal(response.headers.get('Cache-Control'), 'no-store');
});
test('missing, unknown and revoked tokens never reach provider', async () => {
  const env = await setup();
  const forbidden = () => { throw new Error('Must not call provider'); };
  for (const auth of ['', 'Bearer short', `Bearer ${'b'.repeat(43)}`]) {
    assert.equal((await handle(request({ auth }), env, forbidden)).status, 401);
  }
  env.DB.db.exec("UPDATE users SET enabled = 0");
  assert.equal((await handle(request(), env, forbidden)).status, 401);
});
test('bad image, oversized/chunked body, wrong type and request id rejected before quota', async () => {
  const env = await setup();
  for (const [options, status] of [
    [{ body: new Uint8Array(4) }, 415], [{ type: 'image/png' }, 415],
    [{ id: 'bad' }, 400], [{ body: new Uint8Array(MAX_IMAGE_BYTES + 1) }, 413],
  ]) assert.equal((await handle(request(options), env, provider())).status, status);
  const stream = new ReadableStream({ start(c) { c.enqueue(new Uint8Array(MAX_IMAGE_BYTES));
    c.enqueue(jpeg); c.close(); } });
  const req = new Request('https://fitlife.test/v1/analyze', { method: 'POST', duplex: 'half',
    headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'image/jpeg', 'X-Request-Id': 'a'.repeat(32) }, body: stream });
  assert.equal((await handle(req, env, provider())).status, 413);
  assert.equal(env.DB.db.prepare('SELECT COUNT(*) AS n FROM requests').get().n, 0);
});
test('repeat request id reserves at most once', async () => {
  const env = await setup();
  assert.equal((await handle(request(), env, provider())).status, 200);
  assert.equal((await handle(request(), env, provider())).status, 429);
  assert.equal(env.DB.db.prepare('SELECT COUNT(*) AS n FROM requests').get().n, 1);
});
test('atomic reservations cap concurrent calls and reset on next UTC day', async () => {
  const env = await setup();
  env.USER_DAILY_LIMIT = '2'; env.GLOBAL_MINUTE_LIMIT = '60';
  const now = Date.UTC(2026, 9, 20, 12);
  const attempts = await Promise.allSettled(Array.from({ length: 15 }, (_, i) =>
    reserve(env.DB, 'alice', String(i), now, env)));
  assert.equal(attempts.filter(r => r.status === 'fulfilled').length, 2);
  await reserve(env.DB, 'alice', 'tomorrow', now + 86400000, env);
});
test('global daily and minute limits cover different users; revocation rechecked atomically', async () => {
  const env = await setup();
  env.DB.db.prepare('INSERT INTO users(id, token_hash) VALUES (?, ?)').run('bob', 'hash');
  const now = Date.UTC(2026, 9, 20, 12);
  env.GLOBAL_MINUTE_LIMIT = '1';
  await reserve(env.DB, 'alice', '1', now, env);
  await assert.rejects(reserve(env.DB, 'bob', '2', now, env));
  env.GLOBAL_DAILY_LIMIT = '1';
  await assert.rejects(reserve(env.DB, 'bob', '3', now + 61000, env));
  env.DB.db.exec("UPDATE users SET enabled = 0 WHERE id = 'alice'");
  await assert.rejects(reserve(env.DB, 'alice', '4', now + 86400000, env));
});
test('provider failures are sanitized and consume one reservation without auto retry', async () => {
  const env = await setup();
  let calls = 0;
  const response = await handle(request(), env, async () => { calls++;
    return new Response('sensitive provider details', { status: 429 }); });
  assert.equal(response.status, 429);
  assert.deepEqual(await response.json(), { error: 'provider_quota' });
  assert.equal(calls, 1);
  assert.equal(env.DB.db.prepare('SELECT COUNT(*) AS n FROM requests').get().n, 1);
});
test('invalid, blocked and truncated provider results never become food', async () => {
  for (const fetcher of [provider({ ...meal, items: [{ ...food, kcal: -1 }] }),
    async () => Response.json({ candidates: [{ finishReason: 'MAX_TOKENS' }] }),
    async () => Response.json({ promptFeedback: { blockReason: 'SAFETY' } }),
    async () => new Response('invalid-json'),
    async () => new Response('x'.repeat(65537)),
  ]) {
    const result = await handle(request(), await setup(), fetcher);
    assert.ok([422, 502, 413].includes(result.status));
    assert.equal((await result.json()).items, undefined);
  }
});
test('no-food is an empty review, never a guessed fallback', async () => {
  const result = await handle(request(), await setup(), provider({ items: [], warnings: ['Еды не видно.'] }));
  assert.equal(result.status, 200);
  assert.deepEqual((await result.json()).items, []);
});
test('result validation rejects impossible/malformed nutrition and strips arbitrary fields', () => {
  for (const patch of [{ name: '' }, { grams: NaN }, { fiber: 101 },
    { confidence: '99%' }, { protein: 80, fat: 80 }, { kcal: '120' }]) {
    assert.throws(() => validateResult({ ...meal, items: [{ ...food, ...patch }] }));
  }
  assert.deepEqual(validateResult({ ...meal, secret: 'x', items: [{ ...food, url: 'untrusted' }] }), meal);
});
test('health, method, missing config and DB failures do not disclose internals', async () => {
  assert.equal((await handle(new Request('https://fitlife.test/health'), {})).status, 200);
  assert.equal((await handle(new Request('https://fitlife.test/v1/analyze'), {})).status, 405);
  const response = await handle(request(), { DB: {}, GEMINI_API_KEY: 'x', GEMINI_MODEL: 'bad/path' });
  assert.equal(response.status, 503);
  assert.deepEqual(await response.json(), { error: 'configuration' });
});
