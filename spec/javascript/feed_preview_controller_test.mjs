import { test, afterEach } from "node:test"
import assert from "node:assert/strict"
import { installDom } from "./support/dom.mjs"

installDom()

const { Application } = await import("@hotwired/stimulus")
const { default: FeedPreviewController } = await import("../../app/javascript/controllers/feed_preview_controller.js")

const application = Application.start()
application.register("feed-preview", FeedPreviewController)

const FALLBACK = "{game}: {title}"

async function mount(value) {
  document.body.innerHTML = `
    <div data-controller="feed-preview">
      <div data-feed-preview-field>
        <span data-feed-preview-target="reset"><button type="button" data-action="feed-preview#reset">Reset</button></span>
        <textarea data-feed-preview-target="template" data-action="input->feed-preview#render" data-fallback="${FALLBACK}" data-tokens='{"game":"Hades II","title":"Patch 1.4"}'></textarea>
        <div data-feed-preview-target="output"></div>
      </div>
    </div>`
  const input = document.querySelector("textarea")
  input.value = value
  await new Promise((resolve) => setTimeout(resolve, 0))
  return input
}

afterEach(async () => {
  document.body.innerHTML = ""
  await new Promise((resolve) => setTimeout(resolve, 0))
})

test("the reset button starts hidden while the text is the default", async () => {
  await mount(FALLBACK)

  assert.equal(document.querySelector("[data-feed-preview-target=reset]").hidden, true)
})

test("editing the text reveals the reset button", async () => {
  const input = await mount(FALLBACK)
  const reset = document.querySelector("[data-feed-preview-target=reset]")
  assert.equal(reset.hidden, true)

  input.value = "Out now: {title}"
  input.dispatchEvent(new Event("input", { bubbles: true }))

  assert.equal(reset.hidden, false)
})

test("reset restores the default, fires input, repaints the preview and hides the button", async () => {
  const input = await mount("Out now: {title}")
  const inputs = []
  input.addEventListener("input", () => inputs.push(input.value))

  document.querySelector("button").click()

  assert.equal(input.value, FALLBACK)
  assert.deepEqual(inputs, [FALLBACK])
  assert.equal(document.querySelector("[data-feed-preview-target=output]").textContent, "Hades II: Patch 1.4")
  assert.equal(document.querySelector("[data-feed-preview-target=reset]").hidden, true)
})
