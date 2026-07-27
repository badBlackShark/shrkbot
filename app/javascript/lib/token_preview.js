const MENTION_CLASS = "discord-mention"
const EMPTY_HINT_CLASS = "discord-empty-hint"

export function text(value) {
  return document.createTextNode(value)
}

export function pill(value) {
  return styled(MENTION_CLASS, value)
}

export function hint(value) {
  return styled(EMPTY_HINT_CLASS, value)
}

export function nodes(template, pattern, resolve) {
  const out = []
  let last = 0
  let match

  pattern.lastIndex = 0
  while ((match = pattern.exec(template))) {
    if (match.index > last) out.push(text(template.slice(last, match.index)))
    out.push(...resolve(match))
    last = pattern.lastIndex
  }
  if (last < template.length) out.push(text(template.slice(last)))

  return out
}

function styled(className, value) {
  const span = document.createElement("span")
  span.className = className
  span.textContent = value
  return span
}
