import test from "node:test"
import assert from "node:assert/strict"
import { parse } from "../../app/javascript/lib/discord_markdown.js"

function text(value) {
  return { type: "text", value }
}

function paragraph(children) {
  return { type: "paragraph", children }
}

test("plain text becomes a single paragraph with a single text node", () => {
  assert.deepEqual(parse("hello world"), [paragraph([text("hello world")])])
})

test("bold with **", () => {
  assert.deepEqual(parse("**bold**"), [paragraph([{ type: "bold", children: [text("bold")] }])])
})

test("italic with *", () => {
  assert.deepEqual(parse("*italic*"), [paragraph([{ type: "italic", children: [text("italic")] }])])
})

test("underline with __", () => {
  assert.deepEqual(parse("__under__"), [paragraph([{ type: "underline", children: [text("under")] }])])
})

test("strike with ~~", () => {
  assert.deepEqual(parse("~~gone~~"), [paragraph([{ type: "strike", children: [text("gone")] }])])
})

test("spoiler with ||", () => {
  assert.deepEqual(parse("||secret||"), [paragraph([{ type: "spoiler", children: [text("secret")] }])])
})

test("triple star produces bold wrapping italic", () => {
  assert.deepEqual(parse("***x***"), [
    paragraph([{ type: "bold", children: [{ type: "italic", children: [text("x")] }] }])
  ])
})

test("keeps intraword underscores literal", () => {
  assert.deepEqual(parse("snake_case_word"), [paragraph([text("snake_case_word")])])
})

test("single underscore italic still works", () => {
  assert.deepEqual(parse("_x_"), [paragraph([{ type: "italic", children: [text("x")] }])])
})

test("escaped asterisks stay literal and merge into one text node", () => {
  assert.deepEqual(parse("\\*not bold\\*"), [paragraph([text("*not bold*")])])
})

test("single-backtick code holds raw double-star content", () => {
  assert.deepEqual(parse("`**x**`"), [paragraph([{ type: "code", value: "**x**" }])])
})

test("double-backtick code can contain a single backtick", () => {
  assert.deepEqual(parse("``a`b``"), [paragraph([{ type: "code", value: "a`b" }])])
})

test("unclosed double star is literal text", () => {
  assert.deepEqual(parse("**oops"), [paragraph([text("**oops")])])
})

test("headings level 1 through 3", () => {
  assert.deepEqual(parse("# one"), [{ type: "heading", level: 1, children: [text("one")] }])
  assert.deepEqual(parse("## two"), [{ type: "heading", level: 2, children: [text("two")] }])
  assert.deepEqual(parse("### three"), [{ type: "heading", level: 3, children: [text("three")] }])
})

test("four hashes is not a heading", () => {
  assert.deepEqual(parse("#### not a heading"), [paragraph([text("#### not a heading")])])
})

test("subtext with -#", () => {
  assert.deepEqual(parse("-# fine print"), [{ type: "subtext", children: [text("fine print")] }])
})

test("consecutive > lines become one quote block", () => {
  assert.deepEqual(parse("> a\n> b"), [
    { type: "quote", children: [paragraph([text("a\nb")])] }
  ])
})

test(">>> swallows the rest of the message into one quote", () => {
  assert.deepEqual(parse(">>> a\nb\nc"), [
    { type: "quote", children: [paragraph([text("a\nb\nc")])] }
  ])
})

test("fenced code block with a language", () => {
  assert.deepEqual(parse("```js\nconst x = 1\n```"), [
    { type: "code", language: "js", content: "const x = 1" }
  ])
})

test("fenced code block without a language", () => {
  assert.deepEqual(parse("```\nplain\n```"), [
    { type: "code", language: null, content: "plain" }
  ])
})

test("unterminated fence falls back to paragraph text", () => {
  assert.deepEqual(parse("```js\nno closing fence"), [
    paragraph([text("```js\nno closing fence")])
  ])
})

test("bullet list", () => {
  assert.deepEqual(parse("- one\n- two"), [
    { type: "list", ordered: false, start: 1, items: [[paragraph([text("one")])], [paragraph([text("two")])]] }
  ])
})

test("ordered list takes start from the first number", () => {
  assert.deepEqual(parse("5. five\n6. six"), [
    { type: "list", ordered: true, start: 5, items: [[paragraph([text("five")])], [paragraph([text("six")])]] }
  ])
})

test("nested list via two-space indent", () => {
  assert.deepEqual(parse("- top\n  - nested"), [
    {
      type: "list",
      ordered: false,
      start: 1,
      items: [
        [
          paragraph([text("top")]),
          { type: "list", ordered: false, start: 1, items: [[paragraph([text("nested")])]] }
        ]
      ]
    }
  ])
})

test("valid masked link", () => {
  assert.deepEqual(parse("[click](https://example.com)"), [
    paragraph([{ type: "link", href: "https://example.com", children: [text("click")] }])
  ])
})

test("javascript: masked link stays literal text, never a link node", () => {
  const blocks = parse("[click](javascript:alert(1))")
  assert.deepEqual(blocks, [paragraph([text("[click](javascript:alert(1))")])])
  assert.equal(JSON.stringify(blocks).includes('"link"'), false)
})

test("angle autolink", () => {
  assert.deepEqual(parse("<https://example.com>"), [
    paragraph([{ type: "link", href: "https://example.com", children: [text("https://example.com")] }])
  ])
})

test("bare autolink trims trailing punctuation", () => {
  assert.deepEqual(parse("see https://example.com, ok"), [
    paragraph([
      text("see "),
      { type: "link", href: "https://example.com", children: [text("https://example.com")] },
      text(", ok")
    ])
  ])
})

test("blank lines are preserved inside a paragraph", () => {
  assert.deepEqual(parse("a\n\nb"), [paragraph([text("a\n\nb")])])
})

test("adjacent text nodes are merged, never left consecutive", () => {
  const blocks = parse("a\\*b")
  assert.deepEqual(blocks, [paragraph([text("a*b")])])
  assert.equal(blocks[0].children.length, 1)
})

test("empty input parses to an empty array", () => {
  assert.deepEqual(parse(""), [])
})

test("text after a closing fence starts a clean paragraph, not one led by a newline", () => {
  assert.deepEqual(parse("```js\nfoo\n```\nafter"), [
    { type: "code", language: "js", content: "foo" },
    paragraph([text("after")])
  ])
})

test("switching marker type starts a new list rather than extending the old one", () => {
  const blocks = parse("- one\n1. first")
  assert.equal(blocks.length, 2)
  assert.equal(blocks[0].ordered, false)
  assert.equal(blocks[1].ordered, true)
  assert.deepEqual(blocks[1].items, [[paragraph([text("first")])]])
})
