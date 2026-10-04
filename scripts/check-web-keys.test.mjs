import {test} from 'node:test';
import assert from 'node:assert/strict';
import {mkdtempSync, mkdirSync, writeFileSync, rmSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {join} from 'node:path';
import {spawnSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';

const script = fileURLToPath(new URL('./check-web-keys.mjs', import.meta.url));
for (const scenario of ['clean', 'firebase', 'provider']) {
  test(`web scanner: ${scenario}`, () => {
    const root = mkdtempSync(join(tmpdir(), 'megapanel-key-test-'));
    try {
      mkdirSync(join(root, 'lib'));
      mkdirSync(join(root, 'build', 'web'), {recursive: true});
      const publicKey = 'AIza' + 'A'.repeat(35);
      const secret = 'AIza' + 'B'.repeat(35);
      writeFileSync(join(root, 'lib', 'firebase_options.dart'), `apiKey: '${publicKey}'`);
      writeFileSync(join(root, 'build', 'web', 'main.dart.js'), scenario === 'provider' ? secret : scenario === 'firebase' ? publicKey : 'no keys');
      const result = spawnSync(process.execPath, [script], {cwd: root, encoding: 'utf8'});
      assert.equal(result.status, scenario === 'provider' ? 1 : 0);
      assert.equal((result.stdout + result.stderr).includes(secret), false);
    } finally { rmSync(root, {recursive: true, force: true}); }
  });
}
