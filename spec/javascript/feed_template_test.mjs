import { test } from "node:test"
import assert from "node:assert/strict"

const { subjectText } = await import("lib/feed_template")

const tokens = { role: "", game: "Hades", title: "Patch 1.4", author: "" }

test("renders known tokens", () => {
  assert.equal(subjectText("New {game} patch: {title}", tokens), "New Hades patch: Patch 1.4")
})

test("leaves unknown tokens literal", () => {
  assert.equal(subjectText("{nope} {title}", tokens), "{nope} Patch 1.4")
})

test("is empty when only empty tokens remain", () => {
  assert.equal(subjectText("  {role} {author} ", tokens), "")
})
