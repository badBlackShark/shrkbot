import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["list", "template"]

  add() {
    this.seq = this.seq === undefined ? Date.now() : this.seq + 1
    const html = this.templateTarget.innerHTML.replaceAll("NEW_RECORD", this.seq)
    this.listTarget.insertAdjacentHTML("beforeend", html)
    this.notifyDirty()
  }

  remove(event) {
    event.preventDefault()
    event.stopPropagation()
    event.currentTarget.closest("[data-pingable-role]").remove()
    this.notifyDirty()
  }

  notifyDirty() {
    this.element.dispatchEvent(new Event("input", { bubbles: true }))
  }
}
