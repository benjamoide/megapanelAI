import {createRemoteJWKSet, jwtVerify} from 'jose';
import {createHandler} from './handler.mjs';

const keys = createRemoteJWKSet(new URL(
  'https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com'
));

export async function verifyFirebaseToken(token, env, resolver = keys) {
  const {payload} = await jwtVerify(token, resolver, {
    algorithms: ['RS256'], audience: env.FIREBASE_PROJECT_ID,
    issuer: `https://securetoken.google.com/${env.FIREBASE_PROJECT_ID}`,
    requiredClaims: ['exp', 'iat', 'sub', 'auth_time'],
  });
  const now = Math.floor(Date.now() / 1000);
  if (!payload.sub || payload.sub.length > 128 || payload.iat > now ||
      !Number.isFinite(payload.auth_time) || payload.auth_time > now) throw new Error('Invalid token');
  return payload;
}

export async function callGemini(query, env) {
  if (!/^[a-zA-Z0-9.-]+$/.test(env.GEMINI_MODEL)) throw new Error('Invalid model');
  const response = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/${env.GEMINI_MODEL}:generateContent`, {
    method: 'POST', signal: AbortSignal.timeout(20000),
    headers: {'content-type': 'application/json', 'x-goog-api-key': env.GEMINI_API_KEY},
    body: JSON.stringify({
      systemInstruction: {parts: [{text: 'Provide general educational wellness information. Do not prescribe device settings, diagnose, or invent references. For clinical questions advise a qualified clinician. Answer in the language of the question.'}]},
      contents: [{role: 'user', parts: [{text: query}]}],
      generationConfig: {maxOutputTokens: 1024},
    }),
  });
  if (!response.ok) throw new Error('Provider unavailable');
  const data = await response.json();
  const answer = data.candidates?.[0]?.content?.parts?.map(p => p.text || '').join('').trim();
  if (!answer || answer.length > 12000) throw new Error('Invalid provider response');
  return answer;
}

export default {fetch: createHandler({
  verifyToken: verifyFirebaseToken,
  callProvider: callGemini,
  reserveQuota: async (uid, env) => {
    const stub = env.QUOTA.get(env.QUOTA.idFromName('global'));
    const response = await stub.fetch('https://quota/reserve', {
      method: 'POST', body: JSON.stringify({uid}),
    });
    if (response.status === 429) return false;
    if (!response.ok) throw new Error('Quota unavailable');
    return true;
  },
})};

export class DailyQuota {
  constructor(state, env) { this.state = state; this.env = env; }
  async fetch(request) {
    const {uid} = await request.json();
    const userLimit = Number(this.env.USER_DAILY_LIMIT);
    const globalLimit = Number(this.env.GLOBAL_DAILY_LIMIT);
    if (typeof uid !== 'string' || !Number.isSafeInteger(userLimit) || userLimit < 1 ||
        !Number.isSafeInteger(globalLimit) || globalLimit < 1) return new Response(null, {status: 503});
    const day = new Date().toISOString().slice(0, 10);
    const accepted = await this.state.storage.transaction(async tx => {
      let counts = await tx.get('counts');
      if (!counts || counts.day !== day) counts = {day, total: 0, users: {}};
      const used = Object.hasOwn(counts.users, uid) ? counts.users[uid] : 0;
      if (counts.total >= globalLimit || used >= userLimit) return false;
      counts.total++;
      Object.defineProperty(counts.users, uid, {value: used + 1, enumerable: true, configurable: true, writable: true});
      await tx.put('counts', counts);
      return true;
    });
    return new Response(null, {status: accepted ? 204 : 429});
  }
}
