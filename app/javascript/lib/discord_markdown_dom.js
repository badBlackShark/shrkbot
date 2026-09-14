import { parse } from "lib/discord_markdown"

export function render(template, resolveText) {
  return parse(template).map((block) => renderBlock(block, resolveText))
}

function renderBlock(block, resolveText) {
  switch (block.type) {
    case "paragraph":
      return inlineContainer("div", "discord-paragraph", block.children, resolveText)
    case "heading":
      return inlineContainer("div", `discord-heading discord-heading-${block.level}`, block.children, resolveText)
    case "subtext":
      return inlineContainer("div", "discord-subtext", block.children, resolveText)
    case "quote":
      return blockContainer("blockquote", "discord-quote", block.children, resolveText)
    case "code":
      return codeBlock(block, resolveText)
    case "list":
      return list(block, resolveText)
  }
}

function inlineContainer(tag, className, children, resolveText) {
  const el = document.createElement(tag)
  if (className) el.className = className
  el.append(...renderInlines(children, resolveText))
  return el
}

function blockContainer(tag, className, children, resolveText) {
  const el = document.createElement(tag)
  if (className) el.className = className
  el.append(...children.map((child) => renderBlock(child, resolveText)))
  return el
}

function codeBlock(block, resolveText) {
  const pre = document.createElement("pre")
  pre.className = "discord-code-block"
  const code = document.createElement("code")
  code.textContent = plainText(block.content, resolveText)
  pre.append(code)
  return pre
}

function list(block, resolveText) {
  const el = document.createElement(block.ordered ? "ol" : "ul")
  el.className = "discord-list"
  if (block.ordered && block.start !== 1) el.start = block.start
  el.append(...block.items.map((item) => listItem(item, resolveText)))
  return el
}

function listItem(item, resolveText) {
  const li = document.createElement("li")
  li.append(...item.map((child) => renderBlock(child, resolveText)))
  return li
}

function renderInlines(children, resolveText) {
  return children.flatMap((child) => renderInline(child, resolveText))
}

function renderInline(node, resolveText) {
  switch (node.type) {
    case "text":
      return resolveText(node.value)
    case "bold":
      return [wrapInline("strong", null, node.children, resolveText)]
    case "italic":
      return [wrapInline("em", null, node.children, resolveText)]
    case "strike":
      return [wrapInline("s", null, node.children, resolveText)]
    case "underline":
      return [wrapInline("span", "discord-underline", node.children, resolveText)]
    case "spoiler":
      return [spoiler(node.children, resolveText)]
    case "code":
      return [inlineCode(node.value, resolveText)]
    case "link":
      return [link(node, resolveText)]
  }
}

function wrapInline(tag, className, children, resolveText) {
  const el = document.createElement(tag)
  if (className) el.className = className
  el.append(...renderInlines(children, resolveText))
  return el
}

function spoiler(children, resolveText) {
  const span = document.createElement("span")
  span.className = "discord-spoiler"
  span.setAttribute("role", "button")
  span.setAttribute("tabindex", "0")
  span.setAttribute("aria-expanded", "false")
  span.append(...renderInlines(children, resolveText))
  span.addEventListener("click", () => toggleSpoiler(span))
  span.addEventListener("keydown", (event) => {
    if (event.key !== "Enter" && event.key !== " ") return
    event.preventDefault()
    toggleSpoiler(span)
  })
  return span
}

function toggleSpoiler(span) {
  const expanded = span.getAttribute("aria-expanded") === "true"
  span.setAttribute("aria-expanded", expanded ? "false" : "true")
}

function inlineCode(value, resolveText) {
  const code = document.createElement("code")
  code.className = "discord-code"
  code.textContent = plainText(value, resolveText)
  return code
}

function link(node, resolveText) {
  const a = document.createElement("a")
  a.className = "discord-link"
  a.href = node.href
  a.target = "_blank"
  a.rel = "noopener noreferrer nofollow"
  a.append(...renderInlines(node.children, resolveText))
  return a
}

function plainText(value, resolveText) {
  return resolveText(value)
    .map((node) => node.textContent)
    .join("")
}
