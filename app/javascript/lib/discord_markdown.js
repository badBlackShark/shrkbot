const LANG_RE = /^[a-zA-Z0-9+#._-]+$/
const HEADING_RE = /^(#{1,3})\s+(\S.*)$/
const SUBTEXT_RE = /^-#\s+(\S.*)$/
const LIST_RE = /^( *)([-*]|\d{1,9}[.)])\s+(.*)$/
const URL_RE = /^https?:\/\/[^\s<>()]+$/
const BARE_RE = /^https?:\/\/[^\s<>]+/
const TRAILING_RE = /[.,!?;:]/
const WORD_RE = /[A-Za-z0-9]/

const EMPHASIS_DEFS = [
  { tok: "***", triple: true },
  { tok: "**", type: "bold" },
  { tok: "*", type: "italic" },
  { tok: "__", type: "underline", wordBoundary: true },
  { tok: "_", type: "italic", wordBoundary: true },
  { tok: "~~", type: "strike" }
]

export function parse(text) {
  return parseBlocks(text)
}

const BLOCK_MATCHERS = [readFenceBlock, readTailQuote, readQuote, readHeading, readSubtext, readListBlock]

function parseBlocks(text) {
  if (text === "") return []
  const lines = text.split("\n")
  const blocks = []
  let i = 0

  while (i < lines.length) {
    const match = matchBlock(lines, i)
    if (match) {
      blocks.push(match.block)
      if (match.remainder !== undefined) return blocks.concat(parseBlocks(match.remainder))
      i = match.nextIndex
      continue
    }

    const paragraphLines = [lines[i]]
    i++
    while (i < lines.length && !matchBlock(lines, i)) {
      paragraphLines.push(lines[i])
      i++
    }
    blocks.push({ type: "paragraph", children: parseInline(paragraphLines.join("\n")) })
  }

  return blocks
}

function matchBlock(lines, i) {
  for (const matcher of BLOCK_MATCHERS) {
    const match = matcher(lines, i)
    if (match) return match
  }

  return null
}

function readFenceBlock(lines, i) {
  if (!lines[i].startsWith("```")) return null
  return readFence(lines, i)
}

function readTailQuote(lines, i) {
  const line = lines[i]
  if (!line.startsWith(">>> ") && line !== ">>>") return null
  const content = [line.slice(line.length > 3 ? 4 : 3), ...lines.slice(i + 1)].join("\n")
  return { block: { type: "quote", children: parseBlocks(content) }, nextIndex: lines.length }
}

function readQuote(lines, i) {
  if (!isQuoteLine(lines[i])) return null
  const quoted = []
  let next = i
  while (next < lines.length && isQuoteLine(lines[next])) {
    quoted.push(stripQuotePrefix(lines[next]))
    next++
  }

  return { block: { type: "quote", children: parseBlocks(quoted.join("\n")) }, nextIndex: next }
}

function readHeading(lines, i) {
  const heading = lines[i].match(HEADING_RE)
  if (!heading) return null
  return { block: { type: "heading", level: heading[1].length, children: parseInline(heading[2]) }, nextIndex: i + 1 }
}

function readSubtext(lines, i) {
  const subtext = lines[i].match(SUBTEXT_RE)
  if (!subtext) return null
  return { block: { type: "subtext", children: parseInline(subtext[1]) }, nextIndex: i + 1 }
}

function readListBlock(lines, i) {
  if (!LIST_RE.test(lines[i])) return null
  return parseList(lines, i)
}

function isQuoteLine(line) {
  return line.startsWith("> ") || line === ">"
}

function stripQuotePrefix(line) {
  return line === ">" ? "" : line.slice(2)
}

function readFence(lines, i) {
  const line = lines[i]
  const tail = lines.slice(i).join("\n")
  const afterTicks = line.slice(3)
  let language = null
  let contentStart = 3
  if (afterTicks !== "" && LANG_RE.test(afterTicks)) {
    language = afterTicks
    contentStart = line.length + 1
  }

  const closeIdx = tail.indexOf("```", contentStart)
  if (closeIdx === -1) return null
  let content = tail.slice(contentStart, closeIdx)
  if (content.startsWith("\n")) content = content.slice(1)
  if (content.endsWith("\n")) content = content.slice(0, -1)
  const remainder = tail.slice(closeIdx + 3)
  return { block: { type: "code", language, content }, remainder: stripLeadingNewline(remainder) }
}

function stripLeadingNewline(text) {
  return text.startsWith("\n") ? text.slice(1) : text
}

function parseList(lines, start) {
  const baseMatch = lines[start].match(LIST_RE)
  const baseIndent = Math.floor(baseMatch[1].length / 2)
  const ordered = /^\d/.test(baseMatch[2])
  const listStart = ordered ? parseInt(baseMatch[2], 10) : 1
  const items = []
  let i = start

  while (i < lines.length) {
    const m = lines[i].match(LIST_RE)
    if (!m) break
    const indent = Math.floor(m[1].length / 2)
    if (indent < baseIndent) break
    if (indent === baseIndent && /^\d/.test(m[2]) !== ordered) break
    if (indent > baseIndent) {
      const nested = parseList(lines, i)
      items[items.length - 1].push(nested.block)
      i = nested.nextIndex
      continue
    }

    items.push([{ type: "paragraph", children: parseInline(m[3]) }])
    i++
  }

  return { block: { type: "list", ordered, start: listStart, items }, nextIndex: i }
}

const INLINE_RULES = [
  { trigger: (ch) => ch === "`", fn: tryCode },
  { trigger: (ch, text, pos) => ch === "|" && text[pos + 1] === "|", fn: trySpoiler },
  { trigger: (ch) => ch === "*" || ch === "_" || ch === "~", fn: tryEmphasis },
  { trigger: (ch) => ch === "[", fn: tryLink },
  { trigger: (ch) => ch === "<", fn: tryAngle },
  { trigger: (ch) => ch === "h", fn: tryBareLink }
]

function parseInline(text) {
  const nodes = []
  let pos = 0

  while (pos < text.length) {
    const ch = text[pos]
    if (ch === "\\") {
      const next = text[pos + 1]
      if (next !== undefined && !WORD_RE.test(next)) {
        pushText(nodes, next)
        pos += 2
      } else {
        pushText(nodes, "\\")
        pos += 1
      }
      continue
    }

    const match = matchInlineRule(text, pos, ch)
    if (match) {
      if (match.node) nodes.push(match.node)
      else if (match.literal !== undefined) pushText(nodes, match.literal)
      pos = match.nextPos
      continue
    }

    pushText(nodes, ch)
    pos += 1
  }

  return nodes
}

function matchInlineRule(text, pos, ch) {
  for (const rule of INLINE_RULES) {
    if (!rule.trigger(ch, text, pos)) continue
    const result = rule.fn(text, pos)
    if (result) return result
  }
  return null
}

function pushText(nodes, value) {
  if (value === "") return
  const last = nodes[nodes.length - 1]
  if (last && last.type === "text") last.value += value
  else nodes.push({ type: "text", value })
}

function tryCode(text, pos) {
  if (text.startsWith("``", pos)) {
    const close = text.indexOf("``", pos + 2)
    if (close === -1) return null
    return { node: { type: "code", value: text.slice(pos + 2, close) }, nextPos: close + 2 }
  }

  const close = text.indexOf("`", pos + 1)
  if (close === -1) return null
  return { node: { type: "code", value: text.slice(pos + 1, close) }, nextPos: close + 1 }
}

function trySpoiler(text, pos) {
  const close = text.indexOf("||", pos + 2)
  if (close === -1 || close === pos + 2) return null
  return { node: { type: "spoiler", children: parseInline(text.slice(pos + 2, close)) }, nextPos: close + 2 }
}

function tryEmphasis(text, pos) {
  for (const def of EMPHASIS_DEFS) {
    if (!text.startsWith(def.tok, pos)) continue
    if (def.wordBoundary && WORD_RE.test(text[pos - 1] || "")) continue
    const closeIdx = findClose(text, pos, def)
    if (closeIdx === -1) continue
    const contentStart = pos + def.tok.length
    if (closeIdx === contentStart) continue
    const content = text.slice(contentStart, closeIdx)
    const nextPos = closeIdx + def.tok.length
    if (def.triple) {
      return { node: { type: "bold", children: [{ type: "italic", children: parseInline(content) }] }, nextPos }
    }
    return { node: { type: def.type, children: parseInline(content) }, nextPos }
  }

  return null
}

function findClose(text, pos, def) {
  let idx = text.indexOf(def.tok, pos + def.tok.length)
  while (idx !== -1) {
    if (!def.wordBoundary) return idx
    if (!WORD_RE.test(text[idx + def.tok.length] || "")) return idx
    idx = text.indexOf(def.tok, idx + def.tok.length)
  }
  return -1
}

function tryLink(text, pos) {
  const closeBracket = text.indexOf("]", pos + 1)
  if (closeBracket === -1 || text[closeBracket + 1] !== "(") return null
  const closeParen = text.indexOf(")", closeBracket + 2)
  if (closeParen === -1) return null
  const url = text.slice(closeBracket + 2, closeParen).trim()
  if (URL_RE.test(url)) {
    const textPart = text.slice(pos + 1, closeBracket)
    return { node: { type: "link", href: url, children: parseInline(textPart) }, nextPos: closeParen + 1 }
  }

  return { literal: text.slice(pos, closeParen + 1), nextPos: closeParen + 1 }
}

function tryAngle(text, pos) {
  const close = text.indexOf(">", pos + 1)
  if (close === -1) return null
  const inner = text.slice(pos + 1, close)
  if (!URL_RE.test(inner)) return null
  return { node: { type: "link", href: inner, children: [{ type: "text", value: inner }] }, nextPos: close + 1 }
}

function tryBareLink(text, pos) {
  const match = text.slice(pos).match(BARE_RE)
  if (!match) return null
  const raw = match[0]
  let end = raw.length
  while (end > 0 && TRAILING_RE.test(raw[end - 1])) end--
  const url = raw.slice(0, end)
  if (url === "") return null
  return { node: { type: "link", href: url, children: [{ type: "text", value: url }] }, nextPos: pos + url.length }
}
