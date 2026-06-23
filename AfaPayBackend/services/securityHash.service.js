const bcrypt = require('bcryptjs');

let argon2;
try {
  argon2 = require('argon2');
} catch (_) {
  argon2 = null;
}

async function hashSecret(value) {
  const secret = String(value || '');
  if (argon2) {
    return `argon2id:${await argon2.hash(secret, { type: argon2.argon2id })}`;
  }
  return `bcrypt:${await bcrypt.hash(secret, 12)}`;
}

async function verifySecret(hash, value) {
  const stored = String(hash || '');
  const secret = String(value || '');
  if (stored.startsWith('argon2id:') && argon2) {
    return argon2.verify(stored.slice('argon2id:'.length), secret);
  }
  if (stored.startsWith('bcrypt:')) {
    return bcrypt.compare(secret, stored.slice('bcrypt:'.length));
  }
  if (stored.startsWith('$2')) {
    return bcrypt.compare(secret, stored);
  }
  return false;
}

module.exports = {
  hashSecret,
  verifySecret,
  usesArgon2: () => Boolean(argon2),
};
