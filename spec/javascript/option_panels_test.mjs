import { test } from "node:test"
import assert from "node:assert/strict"

const { showPanels } = await import("lib/option_panels")

function panel(value) {
  return { dataset: { value }, hidden: false }
}

test("shows only the panel whose value is selected", () => {
  const panels = [panel("keep"), panel("delete"), panel("mark_ended")]
  showPanels(panels, "delete")
  assert.deepEqual(panels.map((p) => p.hidden), [true, false, true])
})

test("hides every panel when the value matches none", () => {
  const panels = [panel("keep"), panel("delete")]
  showPanels(panels, "other")
  assert.deepEqual(panels.map((p) => p.hidden), [true, true])
})
