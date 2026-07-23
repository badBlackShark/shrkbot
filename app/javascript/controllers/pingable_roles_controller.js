import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["list", "template"]

  connect() {
    // <details> toggle events don't bubble, so capture them to keep the open-set current
    this.onToggle = () => this.persistOpen()
    this.element.addEventListener("toggle", this.onToggle, true)
    // a default-open new card never fires toggle, so also snapshot right before a save
    this.form = this.element.closest("form")
    this.onSubmit = () => this.persistOpen()
    this.form?.addEventListener("submit", this.onSubmit)
    this.restoreOpen()
  }

  disconnect() {
    this.element.removeEventListener("toggle", this.onToggle, true)
    this.form?.removeEventListener("submit", this.onSubmit)
  }

  add() {
    // monotonic so two adds in the same millisecond can't share a field-name index
    this.seq = this.seq === undefined ? Date.now() : this.seq + 1
    const html = this.templateTarget.innerHTML.replaceAll("NEW_RECORD", this.seq)
    this.listTarget.insertAdjacentHTML("beforeend", html)
    this.notifyDirty()
  }

  remove(event) {
    event.preventDefault()
    event.stopPropagation() // the button lives inside <summary>; don't toggle the disclosure
    event.currentTarget.closest("[data-pingable-role]").remove()
    this.notifyDirty()
  }

  notifyDirty() {
    this.element.dispatchEvent(new Event("input", { bubbles: true }))
  }

  // Open/closed state is client-only, so it's lost when a save re-renders this list
  // or a discard reloads the page. Persist the open cards and restore on connect.
  // A card keys on its selected role; a role-less new card has no key and won't reopen.
  restoreOpen() {
    const open = this.openSet()
    this.cards().forEach((card) => {
      if (this.cardKeys(card).some((key) => open.has(key))) card.open = true
    })
  }

  persistOpen() {
    const keys = this.cards().filter((card) => card.open).map((card) => this.cardKeys(card)[0]).filter(Boolean)
    sessionStorage.setItem(this.storageKey, JSON.stringify(keys))
  }

  openSet() {
    try {
      return new Set(JSON.parse(sessionStorage.getItem(this.storageKey) || "[]"))
    } catch {
      return new Set()
    }
  }

  cards() {
    return Array.from(this.element.querySelectorAll("[data-pingable-role]"))
  }

  cardKeys(card) {
    return [card.querySelector("select[name$='[role_id]']")?.value].filter(Boolean)
  }

  get storageKey() {
    return `pingable-roles-open:${window.location.pathname}`
  }
}
