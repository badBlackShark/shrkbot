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

test("exactly-one applies for a single value only", () => {
  assert.equal(warningApplies("exactly-one", ["1"], []), true)
  assert.equal(warningApplies("exactly-one", [], []), false)
  assert.equal(warningApplies("exactly-one", ["1", "1"], []), false)
})

test("watchedValues reads picked options and checked toggles, ignoring companions", () => {
  const form = {
    elements: [
      { name: "a", selectedOptions: [{ value: "" }, { value: "de" }] },
      { name: "b", type: "hidden", value: "0" },
      { name: "b", type: "checkbox", checked: true, value: "1" },
      { name: "c", type: "checkbox", checked: true, value: "1" },
      { name: "d", type: "checkbox", checked: false, value: "1" }
    ]
  }
  assert.deepEqual(watchedValues(form, ["a", "b", "d"]), ["de", "1"])
})
