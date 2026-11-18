import { test, afterEach } from "node:test"
import assert from "node:assert/strict"
import { installDom } from "./support/dom.mjs"

installDom()

const { Application } = await import("@hotwired/stimulus")
const { default: TomSelectController } = await import("../../app/javascript/controllers/tom_select_controller.js")

const application = Application.start()
application.register("tom-select", TomSelectController)

async function connect(attributes = "") {
  document.body.innerHTML = `<select data-controller="tom-select" ${attributes}><option value="a">A</option><option value="b">B</option></select>`
  const element = document.querySelector("select")
  await new Promise((resolve) => setTimeout(resolve, 0))
  return application.getControllerForElementAndIdentifier(element, "tom-select").select
}

afterEach(async () => {
  document.body.innerHTML = ""
  await new Promise((resolve) => setTimeout(resolve, 0))
})

test("a single select keeps only its latest pick", async () => {
  const select = await connect()
  select.addItem("a")
  select.addItem("b")

  assert.deepEqual(select.items, ["b"])
})

test("a multiple select keeps every pick", async () => {
  const select = await connect("multiple")
  select.addItem("a")
  select.addItem("b")

  assert.deepEqual(select.items, ["a", "b"])
})
