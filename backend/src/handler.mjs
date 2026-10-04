const json = (body, status = 200, headers = {}) => new Response(JSON.stringify(body), {
  status, headers: {'content-type': 'application/json', 'cache-control': 'no-store', ...headers},
});

export function createHandler({verifyToken, callProvider, reserveQuota}) {
  return async (request, env) => {
    const origin = request.headers.get('origin');
    const allowed = (env.ALLOWED_ORIGINS || '').split(',').map(x => x.trim());
    if (origin && !allowed.includes(origin)) return json({error: 'forbidden_origin'}, 403);
    const cors = origin ? {'access-control-allow-origin': origin, vary: 'Origin'} : {};
    const reply = (body, status) => json(body, status, cors);
    if (new URL(request.url).pathname !== '/v1/guide') return reply({error: 'not_found'}, 404);
    if (request.method === 'OPTIONS') return new Response(null, {status: 204, headers: {
      ...cors, 'access-control-allow-methods': 'POST',
      'access-control-allow-headers': 'Authorization, Content-Type',
    }});
    if (request.method !== 'POST') return reply({error: 'method_not_allowed'}, 405);
    const uids = (env.ALLOWED_UIDS || '').split(',').map(x => x.trim()).filter(Boolean);
    if (!env.GEMINI_API_KEY || !env.FIREBASE_PROJECT_ID || !env.GEMINI_MODEL || !uids.length) {
      return reply({error: 'not_configured'}, 503);
    }
    const auth = request.headers.get('authorization') || '';
    if (!auth.startsWith('Bearer ') || auth.length > 8192) return reply({error: 'unauthorized'}, 401);
    let identity;
    try { identity = await verifyToken(auth.slice(7), env); }
    catch { return reply({error: 'unauthorized'}, 401); }
    if (!identity.sub || !uids.includes(identity.sub) || identity.email_verified !== true) {
      return reply({error: 'forbidden'}, 403);
    }
    if (!request.headers.get('content-type')?.startsWith('application/json')) {
      return reply({error: 'unsupported_media_type'}, 415);
    }
    let payload;
    try {
      const reader = request.body?.getReader();
      if (!reader) return reply({error: 'invalid_request'}, 400);
      const chunks = [];
      let size = 0;
      for (;;) {
        const {done, value} = await reader.read();
        if (done) break;
        size += value.byteLength;
        if (size > 4096) { await reader.cancel(); return reply({error: 'request_too_large'}, 413); }
        chunks.push(value);
      }
      const bytes = new Uint8Array(size);
      let offset = 0;
      for (const chunk of chunks) { bytes.set(chunk, offset); offset += chunk.length; }
      payload = JSON.parse(new TextDecoder().decode(bytes));
    } catch { return reply({error: 'invalid_request'}, 400); }
    if (!payload || typeof payload.query !== 'string' || !payload.query.trim() || payload.query.length > 500 ||
        Object.keys(payload).some(k => k !== 'query')) return reply({error: 'invalid_request'}, 400);
    try {
      // Failed provider calls consume a reservation to prevent retry-based abuse.
      if (!await reserveQuota(identity.sub, env)) return reply({error: 'quota_exceeded'}, 429);
      const answer = await callProvider(payload.query.trim(), env);
      return reply({answer}, 200);
    } catch { return reply({error: 'temporarily_unavailable'}, 503); }
  };
}
