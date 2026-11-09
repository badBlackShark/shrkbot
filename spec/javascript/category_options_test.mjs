import { test } from "node:test"
import assert from "node:assert/strict"

const { categoryOptions } = await import("lib/category_options")

test("turns each category into an option whose value is the id and name as JSON, id first", () => {
  assert.deepEqual(categoryOptions([{ name: "Hades II", id: "1" }]), [
    { value: '{"id":"1","name":"Hades II"}', text: "Hades II" }
  ])
})

test("is empty for no categories", () => {
  assert.deepEqual(categoryOptions([]), [])
})
