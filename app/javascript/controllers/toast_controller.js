import { Controller } from "@hotwired/stimulus"

// Auto-dismisses a toast after a few seconds; the close button dismisses early.
export default class extends Controller {
  connect() {
    this.timeout = setTimeout(() => this.dismiss(), 5000)
  }

  disconnect() {
    clearTimeout(this.timeout)
  }

  dismiss() {
    this.element.remove()
  }
}
