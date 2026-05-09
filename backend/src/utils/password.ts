import crypto from "crypto";

const HASH_ITERATIONS = 100000;
const KEY_LENGTH = 64;
const DIGEST = "sha512";

export const hashPassword = (password: string) => {
  const salt = crypto.randomBytes(16).toString("hex");
  const hash = crypto
    .pbkdf2Sync(password, salt, HASH_ITERATIONS, KEY_LENGTH, DIGEST)
    .toString("hex");

  return `${salt}:${hash}`;
};

export const verifyPassword = (password: string, storedHash: string) => {
  const [salt, originalHash] = storedHash.split(":");

  if (!salt || !originalHash) {
    return false;
  }

  const derivedHash = crypto
    .pbkdf2Sync(password, salt, HASH_ITERATIONS, KEY_LENGTH, DIGEST)
    .toString("hex");

  return crypto.timingSafeEqual(
    Buffer.from(derivedHash, "hex"),
    Buffer.from(originalHash, "hex"),
  );
};
