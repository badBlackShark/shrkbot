import { existsSync } from "node:fs"

const LIB = new URL("../../../app/javascript/lib/", import.meta.url)
const VENDOR = new URL("../../../vendor/javascript/", import.meta.url)

export async function resolve(specifier, context, next) {
  if (specifier.startsWith("lib/")) {
    return { url: new URL(`${specifier.slice(4)}.js`, LIB).href, shortCircuit: true }
  }

  if (!/^[@a-z]/.test(specifier) || specifier.startsWith("node:")) return next(specifier, context)

  const vendored = new URL(`${specifier.replaceAll("/", "--")}.js`, VENDOR)
  if (existsSync(vendored)) return { url: vendored.href, shortCircuit: true }

  return next(specifier, context)
}
