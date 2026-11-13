import { test } from "node:test"
import assert from "node:assert/strict"

const { syncReset } = await import("lib/number_stepper")

test("hides the reset when the value equals the default", () => {
  const reset = { hidden: false }
  syncReset(reset, "4", 4)
  assert.equal(reset.hidden, true)
})

test("shows the reset when the value differs from the default", () => {
  const reset = { hidden: true }
  syncReset(reset, "6", 4)
  assert.equal(reset.hidden, false)
})

test("shows the reset when the input is empty", () => {
  const reset = { hidden: true }
  syncReset(reset, "", 4)
  assert.equal(reset.hidden, false)
})

test("treats a zero-padded value as equal to the default", () => {
  const reset = { hidden: false }
  syncReset(reset, "04", 4)
  assert.equal(reset.hidden, true)
})
