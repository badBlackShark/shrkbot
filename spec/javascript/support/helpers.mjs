const realSetTimeout = globalThis.setTimeout

export function settle() {
  return new Promise((resolve) => realSetTimeout(resolve, 0))
}

export function click(selector) {
  return document.querySelector(selector).dispatchEvent(new MouseEvent("click", { bubbles: true, cancelable: true }))
}
