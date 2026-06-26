import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["toggle", "content", "overlay", "label"]

  connect() {
    this.update()
    // reset fires before the control's value updates, so re-veil on the next frame
    this.onReset = () => requestAnimationFrame(() => this.update())
    this.element.addEventListener("reset", this.onReset)
  }

  disconnect() {
    this.element.removeEventListener("reset", this.onReset)
  }

  update() {
    const on = this.toggleTarget.checked
    this.contentTarget.inert = !on
    this.contentTarget.classList.toggle("opacity-45", !on)
    if (this.hasOverlayTarget) this.overlayTarget.classList.toggle("hidden", on)
    if (this.hasLabelTarget) {
      this.labelTarget.textContent = on ? this.labelTarget.dataset.on : this.labelTarget.dataset.off
    }
  }

  enable() {
    this.toggleTarget.checked = true
    // a programmatic .checked fires no change event; dispatch one so the gate
    // and the save bar both react as they do to a real toggle click
    this.toggleTarget.dispatchEvent(new Event("change", {bubbles: true}))
  }
}
