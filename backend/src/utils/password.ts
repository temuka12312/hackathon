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

<<<<<<< HEAD
export const verifyPassword = (password: string, passwordHash: string) => {
  const [salt, storedHash] = passwordHash.split(":");

  if (!salt || !storedHash) {
    return false;
  }

  const candidateHash = crypto
=======
export const verifyPassword = (password: string, storedHash: string) => {
  const [salt, originalHash] = storedHash.split(":");

  if (!salt || !originalHash) {
    return false;
  }

  const derivedHash = crypto
>>>>>>> ff4d34b5abbaf7de8c00a97eebfc5677583bfcaa
    .pbkdf2Sync(password, salt, HASH_ITERATIONS, KEY_LENGTH, DIGEST)
    .toString("hex");

  return crypto.timingSafeEqual(
<<<<<<< HEAD
    Buffer.from(candidateHash, "hex"),
    Buffer.from(storedHash, "hex"),
=======
    Buffer.from(derivedHash, "hex"),
    Buffer.from(originalHash, "hex"),
>>>>>>> ff4d34b5abbaf7de8c00a97eebfc5677583bfcaa
  );
};
