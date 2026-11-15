export function baseValue(value, factor) {
  const text = String(value).trim()
  if (text === "") return ""

  const amount = Number(text)
  if (!Number.isFinite(amount)) return text
  if (factor === 1) return Number.isInteger(amount) ? String(amount) : text

  return String(Math.round(amount * factor))
}

export function syncReset(reset, value, defaultValue, factor = 1) {
  const stored = baseValue(value, factor)
  reset.hidden = stored !== "" && Number(stored) === defaultValue
}

export function unitBounds(min, max, factor) {
  return { min: min / factor, max: max / factor }
}

export function stepFor(factor) {
  return factor === 1 ? "1" : "any"
}

export function shownPlaceholder(total, factor) {
  return String(Number((total / factor).toFixed(2)))
}

export function resetAmount(defaultValue, factor) {
  return defaultValue / factor
}
