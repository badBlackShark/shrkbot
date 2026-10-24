import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { key: String }
  static targets = ["details"]

  connect() {
    if (this.details.open) return

    const stored = localStorage.getItem(this.keyValue)
    if (stored === "open") this.details.open = true
  }

  toggle(event) {
    event.preventDefault()
    this.set(!this.details.open)
  }

  sync(event) {
    this.set(event.target.checked)
  }

  set(open) {
    this.details.open = open
    localStorage.setItem(this.keyValue, open ? "open" : "closed")
  }

  get details() {
    return this.hasDetailsTarget ? this.detailsTarget : this.element
  }
}
