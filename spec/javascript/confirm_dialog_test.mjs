import { test } from "node:test"
import assert from "node:assert/strict"

const { install, confirmWith } = await import("lib/confirm_dialog")

function fakeDialog() {
  const dialog = {
    returnValue: "",
    closeListener: null,
    opened: false,
    addEventListener(type, handler) {
      if (type === "close") this.closeListener = handler
    },
    showModal() {
      this.opened = true
    },
    close(value) {
      this.returnValue = value
      this.closeListener()
    }
  }
  return dialog
}

function fakeDoc(dialog = fakeDialog()) {
  const elements = {
    "confirm-dialog": dialog,
    "confirm-dialog-title": { textContent: "" },
    "confirm-dialog-body": { textContent: "" },
    "confirm-dialog-button": { textContent: "" }
  }
  return {
    dialog,
    elements,
    listeners: [],
    getElementById: (id) => elements[id],
    addEventListener(type, handler, capture) {
      this.listeners.push({ type, handler, capture })
    }
  }
}

function withCopy(title, button) {
  return { dataset: { confirmTitle: title, confirmButton: button } }
}

const plain = { dataset: {} }

test("resolves true when the dialog closes with confirm", async () => {
  const doc = fakeDoc()
  const result = confirmWith("Sure?", [plain], doc)
  doc.dialog.close("confirm")
  assert.equal(await result, true)
})

test("resolves false when the dialog closes without a value", async () => {
  const doc = fakeDoc()
  const result = confirmWith("Sure?", [plain], doc)
  doc.dialog.close("")
  assert.equal(await result, false)
})

test("opens the dialog as a modal with a cleared return value", async () => {
  const doc = fakeDoc()
  doc.dialog.returnValue = "confirm"
  const result = confirmWith("Sure?", [plain], doc)
  assert.equal(doc.dialog.opened, true)
  assert.equal(doc.dialog.returnValue, "")
  doc.dialog.close("")
  await result
})

test("puts the message in the body", async () => {
  const doc = fakeDoc()
  const result = confirmWith("This cannot be undone.", [plain], doc)
  assert.equal(doc.elements["confirm-dialog-body"].textContent, "This cannot be undone.")
  doc.dialog.close("")
  await result
})

test("takes title and button from the first source that has copy", async () => {
  const doc = fakeDoc()
  const result = confirmWith("Sure?", [null, plain, withCopy("First?", "Do it"), withCopy("Second?", "Other")], doc)
  assert.equal(doc.elements["confirm-dialog-title"].textContent, "First?")
  assert.equal(doc.elements["confirm-dialog-button"].textContent, "Do it")
  doc.dialog.close("")
  await result
})

test("leaves title and button empty when no source has copy", async () => {
  const doc = fakeDoc()
  const result = confirmWith("Sure?", [undefined, plain], doc)
  assert.equal(doc.elements["confirm-dialog-title"].textContent, "")
  assert.equal(doc.elements["confirm-dialog-button"].textContent, "")
  doc.dialog.close("")
  await result
})

test("uses the clicked turbo-method link when turbo passes only the generated form", async () => {
  const turbo = { config: { forms: {} } }
  const doc = fakeDoc()
  install(turbo, doc)
  const click = doc.listeners.find((listener) => listener.type === "click")
  const link = withCopy("Remove it?", "Remove")
  click.handler({ target: { closest: () => link } })

  const result = turbo.config.forms.confirm("Sure?", plain, null)
  assert.equal(doc.elements["confirm-dialog-title"].textContent, "Remove it?")
  assert.equal(doc.elements["confirm-dialog-button"].textContent, "Remove")
  doc.dialog.close("confirm")
  assert.equal(await result, true)
})

test("closes an open dialog before Turbo caches the page", async () => {
  const turbo = { config: { forms: {} } }
  const doc = fakeDoc()
  install(turbo, doc)
  const result = confirmWith("Sure?", [plain], doc)
  doc.listeners.find((listener) => listener.type === "turbo:before-cache").handler()
  assert.equal(await result, false)
})

test("forgets the link after one confirmation", async () => {
  const turbo = { config: { forms: {} } }
  const doc = fakeDoc()
  install(turbo, doc)
  const click = doc.listeners.find((listener) => listener.type === "click")
  click.handler({ target: { closest: () => withCopy("Remove it?", "Remove") } })

  const first = turbo.config.forms.confirm("Sure?", plain, null)
  doc.dialog.close("")
  await first
  const second = turbo.config.forms.confirm("Sure?", plain, null)
  assert.equal(doc.elements["confirm-dialog-title"].textContent, "")
  doc.dialog.close("")
  await second
})

test("forgets the link when a later click lands outside any confirm link", async () => {
  const turbo = { config: { forms: {} } }
  const doc = fakeDoc()
  install(turbo, doc)
  const click = doc.listeners.find((listener) => listener.type === "click")
  click.handler({ target: { closest: () => withCopy("Remove it?", "Remove") } })
  click.handler({ target: { closest: () => null } })

  const result = turbo.config.forms.confirm("Sure?", plain, null)
  assert.equal(doc.elements["confirm-dialog-title"].textContent, "")
  doc.dialog.close("")
  await result
})
