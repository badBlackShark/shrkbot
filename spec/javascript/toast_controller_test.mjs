import { test, afterEach } from "node:test"
import assert from "node:assert/strict"
import { installDom } from "./support/dom.mjs"
import { settle } from "./support/helpers.mjs"

installDom()

const { Application } = await import("@hotwired/stimulus")
const { default: ToastController } = await import("../../app/javascript/controllers/toast_controller.js")

const application = Application.start()
application.register("toast", ToastController)

const realSetTimeout = globalThis.setTimeout
const realClearTimeout = globalThis.clearTimeout
const scheduled = []
const cleared = []

globalThis.setTimeout = (callback, delay, ...rest) => {
  const handle = realSetTimeout(callback, delay, ...rest)
  if (delay > 0) scheduled.push({ callback, delay, handle })
  return handle
}

globalThis.clearTimeout = (handle) => {
  cleared.push(handle)
  return realClearTimeout(handle)
}

async function mount(attributes = "") {
  document.body.innerHTML = `<div id="toast" data-controller="toast" ${attributes}><button data-action="toast#dismiss">Close</button></div>`
  await settle()
  return document.getElementById("toast")
}

afterEach(async () => {
  document.body.innerHTML = ""
  scheduled.length = 0
  cleared.length = 0
  await settle()
})

test("dismissing plays the leave animation first and leaves the toast in place", async () => {
  const toast = await mount()

  toast.querySelector("button").click()

  assert.equal(toast.classList.contains("toast-leave"), true)
  assert.equal(toast.classList.contains("toast-collapse"), false)
  assert.equal(toast.isConnected, true)
})

test("after the leave animation the toast collapses from its measured height to zero", async () => {
  const toast = await mount()
  Object.defineProperty(toast, "offsetHeight", { value: 42 })
  const heightWhenReflowed = []
  toast.getBoundingClientRect = () => heightWhenReflowed.push(toast.style.height)

  toast.querySelector("button").click()
  toast.dispatchEvent(new Event("animationend"))

  assert.deepEqual(heightWhenReflowed, ["42px"])
  assert.equal(toast.classList.contains("toast-collapse"), true)
  assert.equal(toast.style.height, "0px")
  assert.equal(toast.isConnected, true)
})

test("the toast is removed when its height transition ends, not before", async () => {
  const toast = await mount()
  toast.querySelector("button").click()
  toast.dispatchEvent(new Event("animationend"))

  toast.dispatchEvent(Object.assign(new Event("transitionend"), { propertyName: "padding-block" }))
  assert.equal(toast.isConnected, true)

  toast.dispatchEvent(Object.assign(new Event("transitionend"), { propertyName: "height" }))
  assert.equal(toast.isConnected, false)
})

test("a toast dismisses itself after five seconds", async () => {
  const toast = await mount()

  assert.deepEqual(scheduled.map(({ delay }) => delay), [5000])
  scheduled[0].callback()
  assert.equal(toast.classList.contains("toast-leave"), true)
})

test("removing a toast cancels its pending dismissal", async () => {
  const toast = await mount()

  toast.remove()
  await settle()

  assert.equal(cleared.includes(scheduled[0].handle), true)
})

test("a sticky toast schedules no automatic dismissal", async () => {
  await mount('data-toast-sticky-value="true"')

  assert.equal(scheduled.length, 0)
})
