import { test } from "node:test"
import assert from "node:assert/strict"
import { installFakeDocument, serialize, listenerCount } from "./support/fake_dom.mjs"

installFakeDocument()

const { render } = await import("lib/discord_markdown_dom")

function plain(value) {
  return [document.createTextNode(value)]
}

function pilled(value) {
  const span = document.createElement("span")
  span.className = "discord-mention"
  span.textContent = `@${value.replaceAll("{user}", "newmember")}`
  return [span]
}

function html(template, resolveText = plain) {
  return render(template, resolveText).map(serialize).join("")
}

test("wraps plain text in a paragraph and passes it through the resolver", () => {
  assert.equal(html("hi {user}", pilled), '<div class="discord-paragraph"><span class="discord-mention">@hi newmember</span></div>')
})

test("maps each inline style to its own element", () => {
  assert.equal(
    html("**b** *i* __u__ ~~s~~"),
    '<div class="discord-paragraph"><strong>b</strong> <em>i</em> <span class="discord-underline">u</span> <s>s</s></div>'
  )
})

test("makes a spoiler operable by keyboard as well as mouse", () => {
  const spoiler = render("||secret||", plain)[0].childNodes[0]

  assert.equal(spoiler.attributes.get("role"), "button")
  assert.equal(spoiler.attributes.get("tabindex"), "0")
  assert.equal(spoiler.attributes.get("aria-expanded"), "false")
  assert.equal(listenerCount(spoiler, "click"), 1)
  assert.equal(listenerCount(spoiler, "keydown"), 1)
})

test("opens links in a new tab without leaking the opener", () => {
  assert.equal(
    html("[docs](https://example.com)"),
    '<div class="discord-paragraph"><a class="discord-link" href="https://example.com" target="_blank" rel="noopener noreferrer nofollow">docs</a></div>'
  )
})

test("flattens resolved tokens to plain text inside a code block", () => {
  const code = render("```\n{user} joined\n```", pilled)[0].childNodes[0]

  assert.equal(code.nodeName, "code")
  assert.equal(code.childNodes.length, 0)
  assert.equal(code.textContent, "@newmember joined")
})

test("flattens resolved tokens to plain text inside an inline code span", () => {
  const code = render("`{user}`", pilled)[0].childNodes[0]

  assert.equal(code.nodeName, "code")
  assert.equal(code.childNodes.length, 0)
  assert.equal(code.textContent, "@newmember")
})

test("numbers an ordered list from its first marker, and only when it isn't one", () => {
  assert.equal(html("1. one"), '<ol class="discord-list"><li><div class="discord-paragraph">one</div></li></ol>')
  assert.equal(html("3. three"), '<ol class="discord-list" start="3"><li><div class="discord-paragraph">three</div></li></ol>')
})

test("nests blocks inside a quote", () => {
  assert.equal(
    html("> # title\n> body"),
    '<blockquote class="discord-quote"><div class="discord-heading discord-heading-1">title</div><div class="discord-paragraph">body</div></blockquote>'
  )
})

test("keeps a blank line before a paragraph as leading space in that paragraph", () => {
  assert.equal(html("# a\n\nb"), '<div class="discord-heading discord-heading-1">a</div><div class="discord-paragraph">\nb</div>')
})

test("keeps a blank line between two blocks as an empty paragraph", () => {
  assert.equal(
    html("# a\n\n> q"),
    '<div class="discord-heading discord-heading-1">a</div><div class="discord-paragraph"></div><blockquote class="discord-quote"><div class="discord-paragraph">q</div></blockquote>'
  )
})
