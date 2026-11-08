import { test } from "node:test"
import assert from "node:assert/strict"

const { tokenPattern, previewTemplate } = await import("lib/feed_template")

const tokens = { game: "Hades", title: "Patch 1.4", author: "" }

test("matches exactly the given token names", () => {
  assert.deepEqual([..."{game} {nope} {title}".matchAll(tokenPattern(tokens))].map((match) => match[1]), ["game", "title"])
})

test("previewTemplate keeps typed text over the fallback", () => {
  assert.equal(previewTemplate("{game} is out", "{title}", tokens), "{game} is out")
})

test("previewTemplate falls back when the text is empty", () => {
  assert.equal(previewTemplate("", "{game}: {title}", tokens), "{game}: {title}")
})

test("previewTemplate falls back when the text renders blank", () => {
  assert.equal(previewTemplate("{author}", "{game}: {title}", tokens), "{game}: {title}")
})

test("previewTemplate is empty when there is no fallback", () => {
  assert.equal(previewTemplate("", undefined, tokens), "")
})
