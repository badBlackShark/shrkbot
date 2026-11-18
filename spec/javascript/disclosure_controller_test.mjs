import { test, beforeEach } from "node:test"
import assert from "node:assert/strict"
import { installDom } from "./support/dom.mjs"

const window = installDom()
globalThis.localStorage = window.localStorage
window.matchMedia = () => ({ matches: true })

const { Application } = await import("@hotwired/stimulus")
const { default: DisclosureController } = await import("../../app/javascript/controllers/disclosure_controller.js")

const application = Application.start()
application.register("disclosure", DisclosureController)

let details

async function mount(attributes = "") {
  document.body.innerHTML = `
    <details data-controller="disclosure" ${attributes}>
      <summary data-action="click->disclosure#toggle">
        <span class="title">Title</span>
        <a href="#x" class="link">Link</a>
        <button type="button" class="button">Button</button>
        <input class="input">
        <label class="label">Label</label>
      </summary>
      <p>Body</p>
    </details>`
  await new Promise((resolve) => setTimeout(resolve, 0))
  details = document.querySelector("details")
}

function click(selector) {
  return document.querySelector(selector).dispatchEvent(new MouseEvent("click", { bubbles: true, cancelable: true }))
}

beforeEach(() => localStorage.clear())

test("a click on the summary text toggles the section", async () => {
  await mount()

  assert.equal(click(".title"), false)
  assert.equal(details.open, true)
  assert.equal(click(".title"), false)
  assert.equal(details.open, false)
})

for (const selector of [".link", ".button", ".input", ".label"]) {
  test(`a click on ${selector} inside the summary keeps its own behaviour and remembers nothing`, async () => {
    await mount('data-disclosure-key-value="plugin-a"')

    assert.equal(click(selector), true)
    assert.equal(localStorage.getItem("plugin-a"), null)
  })
}

test("the open state is remembered under the key", async () => {
  await mount('data-disclosure-key-value="plugin-a"')

  click(".title")

  assert.equal(localStorage.getItem("plugin-a"), "open")
})
