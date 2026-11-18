import { test, afterEach } from "node:test"
import assert from "node:assert/strict"
import { installDom } from "./support/dom.mjs"

installDom()

const { Application } = await import("@hotwired/stimulus")
const { default: SegmentedController } = await import("../../app/javascript/controllers/segmented_controller.js")

const application = Application.start()
application.register("segmented", SegmentedController)

async function connect() {
  const buttons = ["a", "b", "c"].map(
    (value, index) =>
      `<button type="button" role="radio" aria-checked="${index === 0}" tabindex="${index === 0 ? 0 : -1}" data-segmented-target="option" data-value="${value}" data-action="segmented#select">${value}</button>`
  )
  document.body.innerHTML = `<div role="radiogroup" data-controller="segmented" data-action="keydown->segmented#keydown" data-segmented-active-class="on" data-segmented-inactive-class="off"><input type="hidden" value="a" data-segmented-target="input">${buttons.join("")}</div>`
  await new Promise((resolve) => setTimeout(resolve, 0))
  return [...document.querySelectorAll("button")]
}

function press(button, key) {
  button.dispatchEvent(new KeyboardEvent("keydown", { key, bubbles: true, cancelable: true }))
}

function state() {
  return [...document.querySelectorAll("button")].map((b) => `${b.getAttribute("aria-checked")}/${b.tabIndex}`)
}

afterEach(async () => {
  document.body.innerHTML = ""
  await new Promise((resolve) => setTimeout(resolve, 0))
})

test("a click selects the option, moves the roving tabindex and fires input", async () => {
  const buttons = await connect()
  let fired = 0
  document.querySelector("input").addEventListener("input", () => fired++)

  buttons[1].click()

  assert.equal(document.querySelector("input").value, "b")
  assert.deepEqual(state(), ["false/-1", "true/0", "false/-1"])
  assert.equal(fired, 1)
})

test("arrow keys move focus and selection, wrapping at both ends", async () => {
  const buttons = await connect()

  press(buttons[0], "ArrowLeft")
  assert.equal(document.querySelector("input").value, "c")
  assert.equal(document.activeElement, buttons[2])

  press(buttons[2], "ArrowRight")
  assert.equal(document.querySelector("input").value, "a")

  press(buttons[0], "ArrowDown")
  assert.equal(document.querySelector("input").value, "b")

  press(buttons[1], "ArrowUp")
  assert.equal(document.querySelector("input").value, "a")
})

test("Home and End jump to the first and last option", async () => {
  const buttons = await connect()

  press(buttons[0], "End")
  assert.equal(document.querySelector("input").value, "c")

  press(buttons[2], "Home")
  assert.equal(document.querySelector("input").value, "a")
})

test("other keys leave the selection alone", async () => {
  const buttons = await connect()

  press(buttons[0], "Tab")

  assert.equal(document.querySelector("input").value, "a")
})
