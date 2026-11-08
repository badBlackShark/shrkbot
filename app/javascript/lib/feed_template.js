export function tokenPattern(tokens) {
  return new RegExp(`\\{(${Object.keys(tokens).join("|")})\\}`, "g")
}

export function previewTemplate(template, fallback, tokens) {
  const rendered = template.replace(tokenPattern(tokens), (_match, name) => tokens[name])
  return rendered.trim() ? template : fallback || ""
}
