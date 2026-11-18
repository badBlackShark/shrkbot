export function syncResetButton(button, input, defaultValue) {
  button.hidden = input.value === defaultValue
}

export function resetToDefault(input, defaultValue) {
  input.value = defaultValue
  input.dispatchEvent(new Event("input", { bubbles: true }))
}
