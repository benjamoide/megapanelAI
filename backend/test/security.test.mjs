import {test} from 'node:test';
import assert from 'node:assert/strict';
import {createHandler} from '../src/handler.mjs';
import {DailyQuota, verifyFirebaseToken} from '../src/worker.mjs';
import {generateKeyPair, SignJWT} from 'jose';

const env = {GEMINI_API_KEY: 'test-only', FIREBASE_PROJECT_ID: 'test-project', GEMINI_MODEL: 'test-model', ALLOWED_UIDS: 'user1', ALLOWED_ORIGINS: 'https://example.com'};
function request(body = {query: 'general wellness'}, token = 'valid') {
  return new Request('https://worker/v1/guide', {method: 'POST', headers: {
    authorization: `Bearer ${token}`, 'content-type': 'application/json', origin: 'https://example.com',
  }, body: JSON.stringify(body)});
}
function handler(overrides = {}) {
  return createHandler({verifyToken: async () => ({sub: 'user1', email_verified: true}), reserveQuota: async () => true,
    callProvider: async () => 'answer', ...overrides});
}
test('fails closed without server configuration', async () => {
  assert.equal((await handler()(request(), {...env, GEMINI_API_KEY: ''})).status, 503);
  assert.equal((await handler()(request(), {...env, ALLOWED_UIDS: ''})).status, 503);
});
test('rejects invalid identity before any paid call', async () => {
  let calls = 0;
  const h = handler({verifyToken: async () => {throw Error('token');}, callProvider: async () => {calls++;}});
  assert.equal((await h(request(), env)).status, 401);
  assert.equal(calls, 0);
});
test('requires allowlisted verified user', async () => {
  for (const identity of [{sub: 'outsider', email_verified: true}, {sub: 'user1', email_verified: false}]) {
    assert.equal((await handler({verifyToken: async () => identity})(request(), env)).status, 403);
  }
});
test('enforces quota before provider', async () => {
  let calls = 0;
  const h = handler({reserveQuota: async () => false, callProvider: async () => {calls++;}});
  assert.equal((await h(request(), env)).status, 429);
  assert.equal(calls, 0);
});
test('rejects injected provider settings and oversized requests', async () => {
  assert.equal((await handler()(request({query: 'q', apiKey: 'x'}), env)).status, 400);
  assert.equal((await handler()(request({query: 'a'.repeat(5000)}), env)).status, 413);
});
test('does not relay upstream errors or secrets', async () => {
  const response = await handler({callProvider: async () => {throw Error('test-only');}})(request(), env);
  assert.equal(response.status, 503);
  assert.equal((await response.text()).includes('test-only'), false);
});
test('valid response includes bounded CORS and no-store', async () => {
  const response = await handler()(request(), env);
  assert.equal(response.headers.get('access-control-allow-origin'), 'https://example.com');
  assert.equal(response.headers.get('cache-control'), 'no-store');
  assert.deepEqual(await response.json(), {answer: 'answer'});
});
test('Firebase signature, audience and expiration are verified', async () => {
  const {privateKey, publicKey} = await generateKeyPair('RS256');
  const now = Math.floor(Date.now() / 1000);
  const sign = (audience, expiration) => new SignJWT({auth_time: now, email_verified: true})
    .setProtectedHeader({alg: 'RS256'}).setSubject('user1').setIssuedAt()
    .setIssuer('https://securetoken.google.com/test-project').setAudience(audience)
    .setExpirationTime(expiration).sign(privateKey);
  assert.equal((await verifyFirebaseToken(await sign('test-project', now + 60), env, publicKey)).sub, 'user1');
  await assert.rejects(verifyFirebaseToken(await sign('wrong-project', now + 60), env, publicKey));
  await assert.rejects(verifyFirebaseToken(await sign('test-project', now - 60), env, publicKey));
  const other = await generateKeyPair('RS256');
  await assert.rejects(verifyFirebaseToken(await sign('test-project', now + 60), env, other.publicKey));
});
test('daily quota persists user and global limits', async () => {
  const db = new Map();
  const tx = {get: async key => structuredClone(db.get(key)), put: async (key, value) => db.set(key, structuredClone(value))};
  const quota = new DailyQuota({storage: {transaction: async fn => fn(tx)}}, {USER_DAILY_LIMIT: '1', GLOBAL_DAILY_LIMIT: '2'});
  const reserve = uid => quota.fetch(new Request('https://quota/reserve', {method: 'POST', body: JSON.stringify({uid})}));
  assert.equal((await reserve('one')).status, 204);
  assert.equal((await reserve('one')).status, 429);
  assert.equal((await reserve('two')).status, 204);
  assert.equal((await reserve('three')).status, 429);
});
