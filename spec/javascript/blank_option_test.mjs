import { test } from "node:test"
import assert from "node:assert/strict"

const { enableBlankOption } = await import("lib/blank_option")

function fakeSelect({ multiple = false, blank = null, required = false } = {}) {
  return {
    multiple,
    querySelector: () => blank,
    getAttribute: (name) => (name === "aria-required" && required ? "true" : null)
  }
}

test("allows the blank option on a single select that has one", () => {
  const blank = { textContent: "" }
  assert.equal(enableBlankOption(fakeSelect({ blank }), "No ping"), true)
})

test("labels an empty blank option with the placeholder", () => {
  const blank = { textContent: "  " }
  enableBlankOption(fakeSelect({ blank }), "No ping")
  assert.equal(blank.textContent, "No ping")
})

test("keeps a blank option that already has text", () => {
  const blank = { textContent: "None" }
  enableBlankOption(fakeSelect({ blank }), "No ping")
  assert.equal(blank.textContent, "None")
})

test("does not allow blank without a blank option", () => {
  assert.equal(enableBlankOption(fakeSelect(), "No ping"), false)
})

test("never allows blank on a multi select", () => {
  const blank = { textContent: "" }
  assert.equal(enableBlankOption(fakeSelect({ multiple: true, blank }), "No ping"), false)
  assert.equal(blank.textContent, "")
})

test("never allows blank on a required single select and leaves its blank text alone", () => {
  const blank = { textContent: "" }
  assert.equal(enableBlankOption(fakeSelect({ blank, required: true }), "Choose a channel"), false)
  assert.equal(blank.textContent, "")
})
