const DIALOG_ID = "confirm-dialog"

export function install(turbo, doc = document) {
  let rememberedLink = null

  // Turbo copies only data-turbo-confirm from a turbo-method link onto its generated form
  doc.addEventListener("click", (event) => {
    rememberedLink = event.target.closest?.("a[data-turbo-confirm]") ?? null
  }, true)

  turbo.config.forms.confirm = (message, form, submitter) => {
    const link = rememberedLink
    rememberedLink = null
    return confirmWith(message, [submitter, form, link], doc)
  }
}

export function confirmWith(message, sources, doc = document) {
  const dialog = doc.getElementById(DIALOG_ID)
  if (!dialog) return Promise.resolve(window.confirm(message))

  const source = sources.find(withCopy)
  const dataset = source?.dataset ?? {}
  doc.getElementById("confirm-dialog-title").textContent = dataset.confirmTitle || dialog.dataset.defaultTitle
  doc.getElementById("confirm-dialog-body").textContent = message
  doc.getElementById("confirm-dialog-button").textContent = dataset.confirmButton || dialog.dataset.defaultButton

  return new Promise((resolve) => {
    dialog.addEventListener("close", () => resolve(dialog.returnValue === "confirm"), { once: true })
    dialog.returnValue = ""
    dialog.showModal()
  })
}

function withCopy(element) {
  return element?.dataset?.confirmTitle || element?.dataset?.confirmButton
}
