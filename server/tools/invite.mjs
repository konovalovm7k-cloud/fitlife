import { randomBytes, createHash } from 'node:crypto';
import { mkdirSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';

const name = process.argv[2];
if (!/^[a-z0-9-]{1,40}$/.test(name ?? '')) {
  console.error('Usage: node tools/invite.mjs user-name');
  process.exit(1);
}
const token = randomBytes(32).toString('base64url');
const hash = createHash('sha256').update(token).digest('hex');
mkdirSync('private', { recursive: true, mode: 0o700 });
const file = resolve('private', `${name}.txt`);
writeFileSync(file, token + '\n', { mode: 0o600, flag: 'wx' });
writeFileSync(resolve('private', `${name}.sql`),
  `INSERT INTO users(id, token_hash) VALUES ('${name}', '${hash}');\n`,
  { mode: 0o600, flag: 'wx' });
console.log(`Created private/${name}.sql and private/${name}.txt. Import SQL; share the code privately.`);
