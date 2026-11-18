import { test, afterEach } from "node:test"
import assert from "node:assert/strict"
import { installDom } from "./support/dom.mjs"

installDom()

const { Application } = await import("@hotwired/stimulus")
const { default: ToastController } = await import("../../app/javascript/controllers/toast_controller.js")

const application = Application.start()
application.register("toast", ToastController)

const AUTO_DISMISS_MS = 5000
const realSetTimeout = globalThis.setTimeout
const scheduled = []

globalThis.setTimeout = (callback, delay, ...rest) => {
  if (delay === AUTO_DISMISS_MS) scheduled.push(callback)
  return realSetTimeout(callback, delay, ...rest)
}

async function settle() {
  await new Promise((resolve) => realSetTimeout(resolve, 0))
}

async function mount(attributes = "") {
  document.body.innerHTML = `<div id="toast" data-controller="toast" ${attributes}><button data-action="toast#dismiss">Close</button></div>`
  await settle()
  return document.getElementById("toast")
}

afterEach(async () => {
  document.body.innerHTML = ""
  scheduled.length = 0
  await settle()
})

test("dismissing plays the leave animation and removes the toast only when it ends", async () => {
  const toast = await mount()

  toast.querySelector("button").click()
  assert.equal(toast.classList.contains("toast-leave"), true)
  assert.equal(toast.isConnected, true)

  toast.dispatchEvent(new Event("animationend"))
  assert.equal(toast.isConnected, false)
})

test("a toast dismisses itself after five seconds", async () => {
  const toast = await mount()

  assert.equal(scheduled.length, 1)
  scheduled[0]()
  assert.equal(toast.classList.contains("toast-leave"), true)
})

test("a sticky toast schedules no automatic dismissal", async () => {
  await mount('data-toast-sticky-value="true"')

  assert.equal(scheduled.length, 0)
})
