import { test } from "node:test"
import assert from "node:assert/strict"

const { roleSelectFor, pingedRoleName } = await import("lib/role_scope")

function scoped(...contained) {
  return { contains: (select) => contained.includes(select) }
}

function input(scope) {
  return { closest: () => scope }
}

const inScope = { id: "in", value: "7" }
const emptyInScope = { id: "empty", value: "" }
const other = { id: "other", value: "1" }
const outside = { id: "outside", value: "2" }

test("prefers the scoped select when it has a value", () => {
  assert.equal(roleSelectFor(input(scoped(inScope)), [other, inScope]), inScope)
})

test("falls back to the first select when the scoped one is empty", () => {
  assert.equal(roleSelectFor(input(scoped(emptyInScope)), [other, emptyInScope]), other)
})

test("falls back to the first select when the scope holds none", () => {
  assert.equal(roleSelectFor(input(scoped()), [outside, other]), outside)
})

test("falls back to the first select when the input has no scope", () => {
  assert.equal(roleSelectFor(input(null), [outside, other]), outside)
})

test("is undefined without any select", () => {
  assert.equal(roleSelectFor(input(null), []), undefined)
})

function selecting(value, text) {
  return { selectedOptions: [{ value, text }] }
}

test("names the picked role", () => {
  assert.equal(pingedRoleName(selecting("7", "Raiders")), "Raiders")
})

test("names no role for the blank option", () => {
  assert.equal(pingedRoleName(selecting("", "Same as above")), "")
})

test("names no role for the no-ping option", () => {
  assert.equal(pingedRoleName(selecting("0", "No ping")), "")
})

test("keeps the no-ping override over the top select", () => {
  const noPing = { id: "noping", value: "0" }
  assert.equal(roleSelectFor(input(scoped(noPing)), [other, noPing]), noPing)
})
