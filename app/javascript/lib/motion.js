export function reducedMotion(env = window) {
  return env.matchMedia("(prefers-reduced-motion: reduce)").matches
}

export function token(name, env = window) {
  return env.getComputedStyle(env.document.documentElement).getPropertyValue(name).trim()
}

export function milliseconds(name, env = window) {
  const value = token(name, env)
  return parseFloat(value) * (value.endsWith("ms") ? 1 : 1000)
}
