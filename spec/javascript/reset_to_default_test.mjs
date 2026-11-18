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

test("shows the button when the input is empty", () => {
  const button = { hidden: true }
  syncResetButton(button, { value: "" }, "Hello")
  assert.equal(button.hidden, false)
})

test("restores the default and announces it with a bubbling input event", () => {
  const events = []
  const input = { value: "edited", dispatchEvent: (event) => events.push(event) }
  resetToDefault(input, "Hello")
  assert.equal(input.value, "Hello")
  assert.equal(events.length, 1)
  assert.equal(events[0].type, "input")
  assert.equal(events[0].bubbles, true)
})
