import { test } from 'node:test';
import assert from 'node:assert/strict';
import { DatabaseSync } from 'node:sqlite';
import { readFileSync } from 'node:fs';
import { handle, hashToken, validateChefResult, chefSchema } from '../src/worker.mjs';
import { chefCatalogue, chefCatalogueVersion } from '../src/chef_catalogue.mjs';

const token = 'a'.repeat(43);
const first = chefCatalogue[0].recordId;
const second = chefCatalogue[1].recordId;
const proposal = { items: [{ recordId: first, grams: 150.5 }], warnings: ['check_portions'] };

async function setup() {
  const db = new DatabaseSync(':memory:');
  db.exec(readFileSync(new URL('../migrations/0001.sql', import.meta.url), 'utf8'));
  db.prepare('INSERT INTO users(id, token_hash) VALUES (?, ?)').run('alice', await hashToken(token));
  const DB = { prepare(sql) {
    const statement = db.prepare(sql);
    return { bind: (...values) => ({ first: async () => statement.get(...values) ?? null,
      run: async () => ({ meta: { changes: Number(statement.run(...values).changes) } }) }) };
  } };
  return { DB, db, GEMINI_API_KEY: 'test-only', GEMINI_MODEL: 'gemini-3.5-flash-lite' };
}
function request({ id = 'a'.repeat(32), auth = token, body, type = 'application/json', method = 'POST', path = '/v2/chef' } = {}) {
  return new Request(`https://fitlife.test${path}`, { method, headers: {
    Authorization: `Bearer ${auth}`, 'X-Request-Id': id, 'Content-Type': type,
  }, body: method === 'GET' ? undefined : body ?? JSON.stringify({ text: 'Яблоко и банан' }) });
}
function provider(result = proposal) {
  return async () => Response.json({ candidates: [{ finishReason: 'STOP', content: {
    parts: [{ text: JSON.stringify(result) }],
  } }] });
}

test('Chef catalogue matches shared/client identities and sourced asset, excludes dry grains', () => {
  const shared = JSON.parse(readFileSync(new URL('../../shared/chef_catalogue.json', import.meta.url), 'utf8'));
  assert.equal(shared.version, chefCatalogueVersion);
  assert.deepEqual(shared.foods, chefCatalogue);
  assert.equal(chefCatalogue.length, 18);
  assert.equal(new Set(chefCatalogue.map(f => f.recordId)).size, 18);
  const asset = JSON.parse(readFileSync(new URL('../../assets/data/food_catalog.json', import.meta.url), 'utf8'));
  for (const food of chefCatalogue) {
    const row = asset.foods.find(r => `imported_${r.id}` === food.recordId);
    assert.ok(row);
    assert.equal(food.name, row.name);
    assert.ok(!['11-857', '11-788'].includes(row.food_code));
    assert.deepEqual(Object.keys(food), ['recordId', 'name']);
  }
});

test('authenticated Chef uses only ready catalogue identities, one low-output model request', async () => {
  const env = await setup();
  let calls = 0;
  const result = await handle(request(), env, async (_url, options) => {
    calls++;
    const input = JSON.parse(options.body);
    assert.deepEqual(input.generationConfig.responseSchema, chefSchema);
    assert.equal(input.generationConfig.maxOutputTokens, 1024);
    const supplied = JSON.parse(input.contents[0].parts[0].text);
    assert.equal(supplied.pantry, 'Яблоко и банан');
    assert.deepEqual(supplied.catalogue, chefCatalogue);
    assert.match(input.systemInstruction.parts[0].text, /untrusted data/);
    assert.match(input.systemInstruction.parts[0].text, /No calories/);
    assert.deepEqual(Object.keys(chefSchema.properties.items.items.properties), ['recordId', 'grams']);
    return provider()();
  });
  assert.equal(result.status, 200);
  assert.deepEqual(await result.json(), { version: 1, kind: 'chef', requestId: 'a'.repeat(32),
    catalogueVersion: chefCatalogueVersion, ...proposal });
  assert.equal(calls, 1);
  assert.equal(env.db.prepare('SELECT COUNT(*) AS n FROM requests').get().n, 1);
  assert.equal(result.headers.get('Cache-Control'), 'no-store');
});

test('Chef strips generated nutrients, titles, instructions and forged sources at every level', async () => {
  const malicious = { ...proposal, title: '100 kcal', instructions: ['Fast for 8 hours'], kcal: 100,
    sourceUrl: 'https://invented.example', items: [{ ...proposal.items[0], name: '100 kcal apple',
      kcal: 100, protein: 99, fiber: 50, satietyHours: 4, source: { reference: 'invented' } }] };
  const response = await handle(request(), await setup(), provider(malicious));
  assert.equal(response.status, 200);
  const clean = await response.json();
  assert.deepEqual(clean.items, proposal.items);
  assert.deepEqual(Object.keys(clean), ['version', 'kind', 'requestId', 'catalogueVersion', 'items', 'warnings']);
});

test('Chef rejects invented/dry/duplicate identities, bad grams, excess mass and advice warnings', () => {
  for (const items of [
    [{ recordId: 'invented', grams: 100 }], [{ recordId: 'imported_cofid_2021_11-857', grams: 100 }],
    [proposal.items[0], proposal.items[0]], [{ recordId: first, grams: '100' }],
    [{ recordId: first, grams: 0 }], [{ recordId: first, grams: Infinity }],
    [{ recordId: first, grams: 2000 }, { recordId: second, grams: 2000 }],
  ]) assert.throws(() => validateChefResult({ items, warnings: [] }));
  for (const warnings of [['100 kcal'], ['unknown'], ['no_match'], Array(5).fill('check_labels')]) {
    assert.throws(() => validateChefResult({ ...proposal, warnings }));
  }
  assert.throws(() => validateChefResult({ items: [], warnings: [] }));
  assert.deepEqual(validateChefResult({ items: [], warnings: ['no_match'] }), { items: [], warnings: ['no_match'] });
});

test('Chef validates auth, method, request ID, type, UTF-8 and body before quota/provider', async () => {
  const env = await setup();
  const forbidden = () => { throw new Error('Must not call provider'); };
  for (const [options, status] of [
    [{ auth: 'short' }, 401], [{ auth: 'b'.repeat(43) }, 401], [{ method: 'GET' }, 405],
    [{ id: 'bad' }, 400], [{ type: 'image/jpeg' }, 415], [{ body: '{}' }, 400],
    [{ body: JSON.stringify({ text: 'x', targetKcal: 100 }) }, 400],
    [{ body: new Uint8Array([195, 40]) }, 400], [{ body: 'x'.repeat(16385) }, 413],
    [{ body: JSON.stringify({ text: 'x'.repeat(2001) }) }, 400],
  ]) assert.equal((await handle(request(options), env, forbidden)).status, status);
  assert.equal(env.db.prepare('SELECT COUNT(*) AS n FROM requests').get().n, 0);
});

test('Chef shares atomic reservations and duplicate IDs with camera/text modes', async () => {
  const env = await setup();
  env.USER_DAILY_LIMIT = '2';
  assert.equal((await handle(request(), env, provider())).status, 200);
  const identity = { items: [], warnings: ['no_food'] };
  assert.equal((await handle(request({ path: '/v2/identify-text' }), env, provider(identity))).status, 429);
  assert.equal((await handle(request({ path: '/v2/identify-text', id: 'b'.repeat(32) }), env, provider(identity))).status, 200);
  assert.equal((await handle(request({ id: 'c'.repeat(32) }), env, provider())).status, 429);
  assert.equal(env.db.prepare('SELECT COUNT(*) AS n FROM requests').get().n, 2);
});

test('Chef makes one provider call on failure, without guessed recipe or secret leakage', async () => {
  let calls = 0;
  const result = await handle(request(), await setup(), async () => {
    calls++;
    return new Response('private provider details', { status: 429 });
  });
  assert.equal(calls, 1);
  assert.equal(result.status, 429);
  assert.deepEqual(await result.json(), { error: 'provider_quota' });
});

test('Chef no-match response remains empty and invalid provider contract is rejected', async () => {
  const empty = { items: [], warnings: ['no_match'] };
  assert.deepEqual((await (await handle(request(), await setup(), provider(empty))).json()).items, []);
  const invalid = await handle(request(), await setup(), provider({ items: [{ recordId: 'fake', grams: 100 }], warnings: [] }));
  assert.equal(invalid.status, 502);
  assert.deepEqual(await invalid.json(), { error: 'invalid_result' });
});
