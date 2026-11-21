import { test, beforeEach } from "node:test"
import assert from "node:assert/strict"
import { installDom } from "./support/dom.mjs"
import { settle, click } from "./support/helpers.mjs"

const window = installDom()
globalThis.localStorage = window.localStorage

function reduceMotion(reduced) {
  window.matchMedia = () => ({ matches: reduced })
}

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
        <a href="#x" class="link">Link <span class="link-text">text</span></a>
        <button type="button" class="button"><span class="button-icon">i</span></button>
        <input class="input">
        <label class="label">Label</label>
        <select class="select"><option>One</option></select>
        <textarea class="textarea"></textarea>
      </summary>
      <p>Body</p>
    </details>`
  await settle()
  details = document.querySelector("details")
}

beforeEach(() => {
  localStorage.clear()
  reduceMotion(true)
})

test("a click on the summary text toggles the section", async () => {
  await mount()

  assert.equal(click(".title"), false)
  assert.equal(details.open, true)
  assert.equal(click(".title"), false)
  assert.equal(details.open, false)
})

for (const selector of [".link", ".link-text", ".button", ".button-icon", ".input", ".label", ".select", ".textarea"]) {
  test(`a click on ${selector} inside the summary keeps its own behaviour and remembers nothing`, async () => {
    await mount('data-disclosure-key-value="plugin-a"')

    assert.equal(click(selector), true)
    assert.equal(localStorage.getItem("plugin-a"), null)
  })
}

test("opening and closing are remembered under the key", async () => {
  await mount('data-disclosure-key-value="plugin-a"')

  click(".title")
  assert.equal(localStorage.getItem("plugin-a"), "open")

  click(".title")
  assert.equal(localStorage.getItem("plugin-a"), "closed")
})

test("a remembered open state restores the section on connect", async () => {
  localStorage.setItem("plugin-a", "open")

  await mount('data-disclosure-key-value="plugin-a"')

  assert.equal(details.open, true)
})

test("a remembered closed state leaves the section closed on connect", async () => {
  localStorage.setItem("plugin-a", "closed")

  await mount('data-disclosure-key-value="plugin-a"')

  assert.equal(details.open, false)
})

test("without a key a toggle remembers nothing", async () => {
  await mount()

  click(".title")

  assert.equal(localStorage.length, 0)
})
