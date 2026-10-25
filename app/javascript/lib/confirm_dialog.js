const DIALOG_ID = "confirm-dialog"

export function install(turbo, doc = document) {
  let rememberedLink = null

  // Turbo copies only data-turbo-confirm from a turbo-method link onto its generated form
  doc.addEventListener("click", (event) => {
    rememberedLink = event.target.closest?.("a[data-turbo-confirm]") ?? null
  }, true)

  // An open dialog would otherwise be cached into the page snapshot and come back on restore
  doc.addEventListener("turbo:before-cache", () => doc.getElementById(DIALOG_ID)?.close())

  let pressedOutside = false

  doc.addEventListener("mousedown", (event) => {
    pressedOutside = onBackdrop(doc, event)
  }, true)

  doc.addEventListener("click", (event) => {
    if (pressedOutside && onBackdrop(doc, event)) doc.getElementById(DIALOG_ID).close("cancel")
  })

  turbo.config.forms.confirm = (message, form, submitter) => {
    const link = rememberedLink
    rememberedLink = null
    return confirmWith(message, [submitter, form, link], doc)
  }
}

export function confirmWith(message, sources, doc = document) {
  const dialog = doc.getElementById(DIALOG_ID)
  const dataset = sources.find(withCopy)?.dataset ?? {}
  doc.getElementById("confirm-dialog-title").textContent = dataset.confirmTitle ?? ""
  doc.getElementById("confirm-dialog-body").textContent = message
  doc.getElementById("confirm-dialog-button").textContent = dataset.confirmButton ?? ""

  return new Promise((resolve) => {
    dialog.addEventListener("close", () => resolve(dialog.returnValue === "confirm"), { once: true })
    dialog.returnValue = ""
    dialog.showModal()
  })
}

function withCopy(element) {
  return element?.dataset?.confirmTitle || element?.dataset?.confirmButton
}

function onBackdrop(doc, event) {
  const dialog = doc.getElementById(DIALOG_ID)
  return event.target === dialog && outside(dialog.getBoundingClientRect(), event)
}

function outside(rect, { clientX, clientY }) {
  return clientX < rect.left || clientX > rect.right || clientY < rect.top || clientY > rect.bottom
}
