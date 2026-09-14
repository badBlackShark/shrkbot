const LIB = new URL("../../../app/javascript/lib/", import.meta.url)

export async function resolve(specifier, context, next) {
  if (!specifier.startsWith("lib/")) return next(specifier, context)

  return { url: new URL(`${specifier.slice(4)}.js`, LIB).href, shortCircuit: true }
}
