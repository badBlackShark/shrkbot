import { test } from "node:test"
import assert from "node:assert/strict"

const { baseValue, resetAmount, shownPlaceholder, stepFor, syncReset, unitBounds } = await import("lib/number_stepper")

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

test("scales bounds to the unit exactly", () => {
  assert.deepEqual(unitBounds(5, 10_080, 60), { min: 5 / 60, max: 168 })
})

test("expands exponent notation in the base unit", () => {
  assert.equal(baseValue("1e3", 1), "1000")
})

test("passes a fraction in the base unit through for the server to reject", () => {
  assert.equal(baseValue("5.5", 1), "5.5")
})

test("converts exponent notation above the base unit", () => {
  assert.equal(baseValue("1e3", 60), "60000")
})

test("rounds a fractional amount to the base unit", () => {
  assert.equal(baseValue("5.5", 60), "330")
  assert.equal(baseValue("1.5", 60), "90")
})

test("passes text that is not a number through for the server to reject", () => {
  assert.equal(baseValue("abc", 60), "abc")
})

test("shows the reset for a fractional amount that differs from the default", () => {
  const reset = { hidden: true }
  syncReset(reset, "5.5", 300, 60)
  assert.equal(reset.hidden, false)
})

test("allows decimals only above the base unit", () => {
  assert.equal(stepFor(1), "1")
  assert.equal(stepFor(60), "any")
})

test("keeps an open upper bound open", () => {
  assert.deepEqual(unitBounds(0, Infinity, 1), { min: 0, max: Infinity })
})

test("shows a placeholder that does not fit with two decimals", () => {
  assert.equal(shownPlaceholder(15, 60), "0.25")
  assert.equal(shownPlaceholder(30, 1), "30")
})

test("shows the default in the reset unit", () => {
  assert.equal(resetAmount(300, 60), 5)
  assert.equal(resetAmount(300, 1), 300)
})
