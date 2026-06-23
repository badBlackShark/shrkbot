import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["toggle", "content", "overlay"]

  connect() {
    this.update()
  }

  update() {
    const on = this.toggleTarget.checked
    this.contentTarget.inert = !on
    this.contentTarget.classList.toggle("opacity-40", !on)
    if (this.hasOverlayTarget) this.overlayTarget.classList.toggle("hidden", on)
  }
}
