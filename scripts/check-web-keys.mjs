import {readFileSync, readdirSync} from 'node:fs';
import {join} from 'node:path';

// Firebase client configuration is public. Provider credentials are not.
const pattern = /AIza[0-9A-Za-z_-]{35}/g;
const firebaseConfig = readFileSync('lib/firebase_options.dart', 'utf8');
const allowed = new Set([...firebaseConfig.matchAll(/apiKey:\s*['"](AIza[0-9A-Za-z_-]{35})['"]/g)].map(m => m[1]));
let unexpected = 0;
function scan(path) {
  for (const item of readdirSync(path, {withFileTypes: true})) {
    const file = join(path, item.name);
    if (item.isDirectory()) scan(file);
    else {
      const matches = readFileSync(file).toString('utf8').match(pattern) || [];
      if (matches.some(key => !allowed.has(key))) {
        console.error(`Unapproved Google key in build artifact: ${file}`);
        unexpected++;
      }
    }
  }
}
scan(process.argv[2] || 'build/web');
if (unexpected) process.exit(1);
console.log('No unapproved Google keys found in web artifacts.');
