export function syncResetButton(button, input, defaultValue, { emptyIsDefault = false } = {}) {
  const value = input.value.trim()
  button.hidden = value === defaultValue.trim() || (emptyIsDefault && value === "")
}

export function resetToDefault(input, defaultValue) {
  input.value = defaultValue
  input.dispatchEvent(new Event("input", { bubbles: true }))
  input.focus()
}
