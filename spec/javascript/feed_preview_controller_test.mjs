import { test, afterEach } from "node:test"
import assert from "node:assert/strict"
import { installDom } from "./support/dom.mjs"
import { settle } from "./support/helpers.mjs"

installDom()

const { Application } = await import("@hotwired/stimulus")
const { default: FeedPreviewController } = await import("../../app/javascript/controllers/feed_preview_controller.js")

const application = Application.start()
application.register("feed-preview", FeedPreviewController)

const FALLBACK = "{game}: {title}"

function field(index) {
  return `
      <div data-feed-preview-field>
        <span data-feed-preview-target="reset"><button type="button" data-action="feed-preview#reset">Reset ${index}</button></span>
        <textarea data-feed-preview-target="template" data-action="input->feed-preview#render" data-fallback="${FALLBACK}" data-tokens='{"game":"Hades II","title":"Patch 1.4"}'></textarea>
        <div data-feed-preview-target="output"></div>
      </div>`
}

async function mount(...values) {
  document.body.innerHTML = `<div data-controller="feed-preview">${values.map((_, index) => field(index)).join("")}</div>`
  const inputs = [...document.querySelectorAll("textarea")]
  inputs.forEach((input, index) => { input.value = values[index] })
  await settle()
  return inputs
}

const resets = () => [...document.querySelectorAll("[data-feed-preview-target=reset]")]
const outputs = () => [...document.querySelectorAll("[data-feed-preview-target=output]")]

afterEach(async () => {
  document.body.innerHTML = ""
  await settle()
})

test("editing the text reveals the reset button of that field only", async () => {
  const [first, second] = await mount(FALLBACK, FALLBACK)
  assert.deepEqual(resets().map((reset) => reset.hidden), [true, true])

  second.value = "Out now: {title}"
  second.dispatchEvent(new Event("input", { bubbles: true }))

  assert.deepEqual(resets().map((reset) => reset.hidden), [true, false])
  assert.equal(first.value, FALLBACK)
})

for (const value of ["", "  \n", ` ${FALLBACK}\n`]) {
  test(`the reset button stays hidden for ${JSON.stringify(value)}`, async () => {
    await mount(value)

    assert.equal(resets()[0].hidden, true)
  })
}

test("reset restores the default of its own field, fires input, repaints, hides the button and focuses the box", async () => {
  const [first, second] = await mount("Out now: {title}", "Mine: {title}")
  const inputs = []
  first.addEventListener("input", () => inputs.push(first.value))
  const focused = []
  first.focus = () => focused.push(first)

  document.querySelectorAll("button")[0].click()

  assert.equal(first.value, FALLBACK)
  assert.equal(second.value, "Mine: {title}")
  assert.deepEqual(inputs, [FALLBACK])
  assert.equal(outputs()[0].textContent, "Hades II: Patch 1.4")
  assert.deepEqual(resets().map((reset) => reset.hidden), [true, false])
  assert.deepEqual(focused, [first])
})
