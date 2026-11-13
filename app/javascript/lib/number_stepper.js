export function syncReset(reset, value, defaultValue) {
  reset.hidden = Number.parseInt(value, 10) === defaultValue
}
