import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { key: String }

  connect() {
    if (this.element.open) return

    const stored = localStorage.getItem(this.keyValue)
    if (stored === "open") this.element.open = true
  }

  toggle(event) {
    event.preventDefault()
    this.element.open = !this.element.open
    localStorage.setItem(this.keyValue, this.element.open ? "open" : "closed")
  }
}
