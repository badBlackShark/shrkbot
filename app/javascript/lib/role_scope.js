export function roleSelectFor(input, selects) {
  const scope = input.closest("[data-feed-preview-scope]")
  return (scope && selects.find((select) => scope.contains(select))) || selects[0]
}
