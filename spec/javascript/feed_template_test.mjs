import { test } from "node:test"
import assert from "node:assert/strict"

const { isEmpty, subjectText, tokenPattern } = await import("lib/feed_template")

const tokens = { role: "", game: "Hades", title: "Patch 1.4", author: "" }

test("renders known tokens", () => {
  assert.equal(subjectText("New {game} patch: {title}", tokens), "New Hades patch: Patch 1.4")
})

test("leaves unknown tokens literal", () => {
  assert.equal(subjectText("{nope} {title}", tokens), "{nope} Patch 1.4")
})

test("matches exactly the given token names", () => {
  assert.deepEqual([..."{game} {nope} {title}".matchAll(tokenPattern(tokens))].map((match) => match[1]), ["game", "title"])
})

test("is empty when only empty tokens remain", () => {
  assert.equal(subjectText("  {role} {author} ", tokens), "")
})

test("isEmpty treats optional tokens as empty", () => {
  const filled = { ...tokens, author: "Jane Doe" }

  assert.equal(isEmpty("{author}", filled, ["author"]), true)
  assert.equal(isEmpty("{title}", filled, ["author"]), false)
})
