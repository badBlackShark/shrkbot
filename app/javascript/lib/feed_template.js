export function tokenPattern(tokens) {
  return new RegExp(`\\{(${Object.keys(tokens).join("|")})\\}`, "g")
}

export function subjectText(template, tokens) {
  return template.replace(/\{(\w+)\}/g, (match, name) => (Object.hasOwn(tokens, name) ? tokens[name] : match)).trim()
}
