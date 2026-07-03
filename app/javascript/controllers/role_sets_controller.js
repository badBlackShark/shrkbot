import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["list", "template"]

  connect() {
    // <details> toggle events don't bubble, so capture them to keep the open-set current
    this.onToggle = () => this.persistOpen()
    this.element.addEventListener("toggle", this.onToggle, true)
    this.restoreOpen()
  }

  disconnect() {
    this.element.removeEventListener("toggle", this.onToggle, true)
  }

  add() {
    const uid = Date.now()
    const html = this.templateTarget.innerHTML.replaceAll("NEW_RECORD", uid)
    this.listTarget.insertAdjacentHTML("beforeend", html)
    this.notifyDirty()
    this.listTarget.lastElementChild?.querySelector("[data-role-set-name]")?.focus()
  }

  remove(event) {
    event.preventDefault()
    event.stopPropagation() // the button lives inside <summary>; don't toggle the disclosure
    const card = event.currentTarget.closest("[data-role-set]")
    const id = card.querySelector("[data-role-set-id]")
    if (id?.value) {
      card.querySelector("[data-role-set-destroy]").value = "1"
      card.querySelector("[data-role-set-name]")?.removeAttribute("required")
      card.hidden = true
    } else {
      card.remove()
    }
    this.notifyDirty()
  }

  notifyDirty() {
    this.element.dispatchEvent(new Event("input", {bubbles: true}))
  }

  // Open/closed state is client-only, so it's lost when a save re-renders this
  // list or a discard reloads the page. Persist the open sets (by id) so the
  // same ones reopen. New unsaved sets have no id yet and collapse on save.
  restoreOpen() {
    const open = this.openSet()
    this.cards().forEach((card) => {
      if (open.has(this.cardId(card))) card.open = true
    })
  }

  persistOpen() {
    const ids = this.cards().filter((card) => card.open).map((card) => this.cardId(card)).filter(Boolean)
    sessionStorage.setItem(this.storageKey, JSON.stringify(ids))
  }

  openSet() {
    try {
      return new Set(JSON.parse(sessionStorage.getItem(this.storageKey) || "[]"))
    } catch {
      return new Set()
    }
  }

  cards() {
    return Array.from(this.element.querySelectorAll("[data-role-set]"))
  }

  cardId(card) {
    return card.querySelector("[data-role-set-id]")?.value
  }

  get storageKey() {
    return `role-sets-open:${window.location.pathname}`
  }
}
