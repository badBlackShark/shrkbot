import { test } from "node:test"
import assert from "node:assert/strict"

const { warningApplies, watchedValues } = await import("lib/live_warning")

test("includes-any applies when a value is in the list", () => {
  assert.equal(warningApplies("includes-any", ["2"], ["1", "2"]), true)
  assert.equal(warningApplies("includes-any", ["3"], ["1", "2"]), false)
  assert.equal(warningApplies("includes-any", [], ["1", "2"]), false)
})

test("excludes-all applies when something is picked and none is in the list", () => {
  assert.equal(warningApplies("excludes-all", ["de", "ru"], ["en"]), true)
  assert.equal(warningApplies("excludes-all", ["de", "en"], ["en"]), false)
  assert.equal(warningApplies("excludes-all", [], ["en"]), false)
})

test("watchedValues reads the picked options of the watched selects only", () => {
  const form = {
    elements: [
      { name: "a", selectedOptions: [{ value: "" }, { value: "de" }] },
      { name: "b", type: "hidden", value: "0" },
      { name: "c", selectedOptions: [{ value: "en" }] }
    ]
  }
  assert.deepEqual(watchedValues(form, ["a", "b"]), ["de"])
})
