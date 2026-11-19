import { test } from "node:test"
import assert from "node:assert/strict"

const { syncResetButton, resetToDefault } = await import("lib/reset_to_default")

test("hides the button when the input holds the default", () => {
  const button = { hidden: false }
  syncResetButton(button, { value: "Hello" }, "Hello")
  assert.equal(button.hidden, true)
})

test("shows the button when the input differs from the default", () => {
  const button = { hidden: true }
  syncResetButton(button, { value: "Hello!" }, "Hello")
  assert.equal(button.hidden, false)
})

test("ignores whitespace at the edges when comparing", () => {
  const button = { hidden: false }
  syncResetButton(button, { value: "  Hello\n" }, "Hello")
  assert.equal(button.hidden, true)
})

test("shows the button for an empty input by default", () => {
  const button = { hidden: true }
  syncResetButton(button, { value: "" }, "Hello")
  assert.equal(button.hidden, false)
})

test("hides the button for an empty input when empty means the default", () => {
  const button = { hidden: false }
  syncResetButton(button, { value: " " }, "Hello", { emptyIsDefault: true })
  assert.equal(button.hidden, true)
})

test("restores the default, announces it with a bubbling input event and focuses the input", () => {
  const events = []
  let focused = false
  const input = { value: "edited", dispatchEvent: (event) => events.push(event), focus: () => { focused = true } }
  resetToDefault(input, "Hello")
  assert.equal(input.value, "Hello")
  assert.equal(events.length, 1)
  assert.equal(events[0].type, "input")
  assert.equal(events[0].bubbles, true)
  assert.equal(focused, true)
})
