import { test } from "node:test"
import assert from "node:assert/strict"

const { roleSelectFor } = await import("lib/role_scope")

function scoped(...contained) {
  return { contains: (select) => contained.includes(select) }
}

function input(scope) {
  return { closest: () => scope }
}

const inScope = { id: "in" }
const other = { id: "other" }
const outside = { id: "outside" }

test("prefers the select inside the input's scope", () => {
  assert.equal(roleSelectFor(input(scoped(inScope)), [other, inScope]), inScope)
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
