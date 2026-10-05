# Secure AI integration

The Flutter AI screen uses a named Firebase app (`secure-ai`) for email/password
authentication. This avoids changing the default Firestore client's identity or
moving legacy profile documents. Opening the AI screen requires signing in again.
The legacy profile login is NOT migrated: it still stores passwords in Firestore
and must be addressed separately before treating the whole app as secure.

The client sends only `{query}` with a Firebase ID token to the HTTPS Worker's
`/v1/guide` endpoint. Gemini credentials stay in the Worker's Secret binding.
No provider SDK or Gemini key is needed in web or APK builds. Do not put the secret
in Wrangler vars, source code, build flags, logs, or GitHub.

The Worker requires a verified email and an allowlisted Firebase UID. Its plain
text answer is displayed as information, never converted into panel commands or
saved as executable treatment settings. Quotas and provider failures are shown
without automatic retries or raw server error details.

## Manual acceptance checks

1. Open the updated app, enter an existing profile or guest mode, then Buscador IA.
2. Use the email/password created in Firebase Authentication, not the legacy
   profile password. A wrong password must not expose the query form.
3. With an unverified account, send the verification email, open its link, then
   select `Ya he verificado`. The query form must remain hidden until verified.
4. Ask a short, non-sensitive question. Confirm a text answer appears, with no
   treatment execution or save-to-catalog button.
5. Sign out of AI. Confirm the answer disappears and the login form returns.
6. Leave and reopen the AI screen. It must request login again.
7. Test a verified but non-allowlisted account: the Worker must reject it (403).
8. Test offline mode and a quota rejection (429, using mocks rather than wasting
   real requests). Errors must be readable and must not reveal tokens or keys.
9. Confirm panel connection and the existing profile history are unchanged.

Automated checks: `flutter analyze`, `flutter test`, backend `npm test`, and
`node scripts/check-web-keys.mjs` after a release web build.
Real email delivery, provider access, Android installation, and BLE behavior
require manual testing; mocked tests do not establish those outcomes.
