export const TOKEN = /\{(role|game|title|url|author|feed)\}/g

export function subjectText(template, tokens) {
  return template.replace(/\{(\w+)\}/g, (match, name) => (Object.hasOwn(tokens, name) ? tokens[name] : match)).trim()
}
