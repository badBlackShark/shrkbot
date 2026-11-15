export function roleSelectFor(input, selects) {
  const scope = input.closest("[data-feed-preview-scope]")
  const override = scope && selects.find((select) => scope.contains(select))
  return override && override.value ? override : selects[0]
}

export const NO_PING = "0"

export function pingedRoleName(select) {
  const selected = select && select.selectedOptions[0]
  return selected && selected.value && selected.value !== NO_PING ? selected.text : ""
}
