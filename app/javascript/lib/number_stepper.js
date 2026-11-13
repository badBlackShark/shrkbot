export function syncReset(reset, value, defaultValue, factor = 1) {
  reset.hidden = Number.parseInt(value, 10) * factor === defaultValue
}

export function baseValue(value, factor) {
  const amount = Number.parseInt(value, 10)
  return Number.isNaN(amount) ? "" : String(amount * factor)
}

export function unitBounds(min, max, factor) {
  return { min: Math.ceil(min / factor), max: Math.floor(max / factor) }
}

export function shownPlaceholder(total, factor) {
  return String(Number((total / factor).toFixed(2)))
}
