export function roleSelectFor(input, selects) {
  const scope = input.closest("[data-feed-preview-scope]")
  const override = scope && selects.find((select) => scope.contains(select))
  return override && override.value ? override : selects[0]
}
