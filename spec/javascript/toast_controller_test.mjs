import { test, afterEach } from "node:test"
import assert from "node:assert/strict"
import { installDom } from "./support/dom.mjs"
import { settle } from "./support/helpers.mjs"

installDom()

const { Application } = await import("@hotwired/stimulus")
const { default: ToastController } = await import("../../app/javascript/controllers/toast_controller.js")

const application = Application.start()
application.register("toast", ToastController)

const SLOW_MS = 260
document.documentElement.style.setProperty("--dur-slow", `${SLOW_MS}ms`)

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

function leave(toast, animationName = "toastLeave") {
  toast.dispatchEvent(Object.assign(new Event("animationend"), { animationName }))
}

function endTransition(toast, type, propertyName = "grid-template-rows") {
  toast.dispatchEvent(Object.assign(new Event(type), { propertyName }))
}

async function dismissed() {
  const toast = await mount()
  toast.querySelector("button").click()
  return toast
}

test("dismissing plays the leave animation first and leaves the toast in place", async () => {
  const toast = await dismissed()

  assert.equal(toast.classList.contains("toast-leave"), true)
  assert.equal(toast.classList.contains("toast-collapse"), false)
  assert.equal(toast.isConnected, true)
})

test("an animation that is not the leave animation does not start the collapse", async () => {
  const toast = await dismissed()

  leave(toast, "toastEnter")

  assert.equal(toast.classList.contains("toast-collapse"), false)
})

test("after the leave animation the toast collapses", async () => {
  const toast = await dismissed()

  leave(toast)

  assert.equal(toast.classList.contains("toast-collapse"), true)
  assert.equal(toast.isConnected, true)
})

for (const type of ["transitionend", "transitioncancel"]) {
  test(`the toast is removed on ${type} of its row collapse, not before`, async () => {
    const toast = await dismissed()
    leave(toast)

    endTransition(toast, type, "opacity")
    assert.equal(toast.isConnected, true)

    endTransition(toast, type)
    assert.equal(toast.isConnected, false)
  })
}

test("a collapse whose transition never reports is removed by the fallback timer", async () => {
  const toast = await dismissed()
  leave(toast)

  const fallback = scheduled.find(({ delay }) => delay === SLOW_MS)
  fallback.callback()

  assert.equal(toast.isConnected, false)
})

test("a second dismiss during the leave animation collapses only once", async () => {
  const toast = await dismissed()

  toast.querySelector("button").click()
  leave(toast)
  leave(toast)

  assert.equal(scheduled.filter(({ delay }) => delay === SLOW_MS).length, 1)
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
