export function tokenPattern(tokens) {
  return new RegExp(`\\{(${Object.keys(tokens).join("|")})\\}`, "g")
}

export function subjectText(template, tokens) {
  return template.replace(/\{(\w+)\}/g, (match, name) => (Object.hasOwn(tokens, name) ? tokens[name] : match)).trim()
}

export function isEmpty(template, tokens, optional) {
  return subjectText(template, { ...tokens, ...Object.fromEntries(optional.map((name) => [name, ""])) }) === ""
}
