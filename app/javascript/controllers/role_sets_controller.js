import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["list", "template"]

  add() {
    const uid = Date.now()
    const html = this.templateTarget.innerHTML.replaceAll("NEW_RECORD", uid)
    this.listTarget.insertAdjacentHTML("beforeend", html)
    this.notifyDirty()
    this.listTarget.lastElementChild?.querySelector("[data-role-set-name]")?.focus()
  }

  remove(event) {
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
    this.element.dispatchEvent(new Event("input", { bubbles: true }))
  }
}
