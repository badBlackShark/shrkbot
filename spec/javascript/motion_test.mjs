import { test } from "node:test"
import assert from "node:assert/strict"

const { milliseconds, token } = await import("lib/motion")

function envWith(tokens) {
  return {
    document: { documentElement: {} },
    getComputedStyle: () => ({ getPropertyValue: (name) => tokens[name] })
  }
}

test("reads a duration the way the source stylesheet writes it", () => {
  assert.equal(milliseconds("--dur-base", envWith({ "--dur-base": " 180ms" })), 180)
})

test("reads a duration the way the minified stylesheet writes it", () => {
  assert.equal(milliseconds("--dur-base", envWith({ "--dur-base": ".18s" })), 180)
})

test("trims the whitespace a custom property keeps", () => {
  assert.equal(token("--ease-standard", envWith({ "--ease-standard": " cubic-bezier(.2, 0, 0, 1)" })), "cubic-bezier(.2, 0, 0, 1)")
})
