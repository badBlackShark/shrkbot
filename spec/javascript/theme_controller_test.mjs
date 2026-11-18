import { test, beforeEach } from "node:test"
import assert from "node:assert/strict"
import { installDom } from "./support/dom.mjs"

const window = installDom()
globalThis.localStorage = window.localStorage

const { Application } = await import("@hotwired/stimulus")
const { default: ThemeController } = await import("../../app/javascript/controllers/theme_controller.js")

const application = Application.start()
application.register("theme", ThemeController)

window.HTMLElement.prototype.animate = () => ({ finished: Promise.resolve() })

const root = document.documentElement

function supportAnimatedProperties(supported) {
  Object.defineProperty(window, "CSS", { value: supported ? { registerProperty() {} } : {}, configurable: true })
}

beforeEach(async () => {
  root.dataset.theme = "light"
  root.classList.remove("theme-inking")
  supportAnimatedProperties(false)
  localStorage.clear()
  document.body.innerHTML = '<button data-controller="theme" data-action="theme#toggle">Theme</button>'
  await new Promise((resolve) => setTimeout(resolve, 0))
})

test("toggling flips the theme and remembers it", () => {
  document.querySelector("button").click()

  assert.equal(root.dataset.theme, "dark")
  assert.equal(localStorage.getItem("shrk-theme"), "dark")
})

test("toggling while the ink transition runs changes nothing", async () => {
  supportAnimatedProperties(true)
  root.classList.add("theme-inking")

  document.querySelector("button").click()
  await new Promise((resolve) => setTimeout(resolve, 0))

  assert.equal(root.dataset.theme, "light")
  assert.equal(localStorage.getItem("shrk-theme"), null)
})
