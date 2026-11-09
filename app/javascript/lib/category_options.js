export function categoryOptions(json) {
  return json.map(({ id, name }) => ({ value: JSON.stringify({ id, name }), text: name }))
}
