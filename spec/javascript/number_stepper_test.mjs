import { test } from "node:test"
import assert from "node:assert/strict"

const { baseValue, shownPlaceholder, syncReset, unitBounds } = await import("lib/number_stepper")

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

test("compares the value in base units", () => {
  const reset = { hidden: false }
  syncReset(reset, "5", 300, 60)
  assert.equal(reset.hidden, true)
})

test("shows the reset when the unit changes the value", () => {
  const reset = { hidden: true }
  syncReset(reset, "5", 300, 1)
  assert.equal(reset.hidden, false)
})

test("converts the shown value to base units", () => {
  assert.equal(baseValue("5", 60), "300")
})

test("submits empty for an empty input", () => {
  assert.equal(baseValue("", 60), "")
})

test("scales bounds to the unit, rounding inward", () => {
  assert.deepEqual(unitBounds(5, 10_080, 60), { min: 1, max: 168 })
})

test("keeps an open upper bound open", () => {
  assert.deepEqual(unitBounds(0, Infinity, 1), { min: 0, max: Infinity })
})

test("shows a placeholder that does not fit with two decimals", () => {
  assert.equal(shownPlaceholder(15, 60), "0.25")
  assert.equal(shownPlaceholder(30, 1), "30")
})
