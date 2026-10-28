import { test } from "node:test"
import assert from "node:assert/strict"

const { tokenPattern } = await import("lib/feed_template")

const tokens = { game: "Hades", title: "Patch 1.4", author: "" }

test("matches exactly the given token names", () => {
  assert.deepEqual([..."{game} {nope} {title}".matchAll(tokenPattern(tokens))].map((match) => match[1]), ["game", "title"])
})
