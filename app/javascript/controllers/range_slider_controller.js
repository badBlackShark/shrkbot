import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["range", "hidden", "readout"]

  update() {
    const pct = parseInt(this.rangeTarget.value, 10)
    this.readoutTarget.textContent = `${pct}%`
    this.hiddenTarget.value = (pct / 100).toFixed(2)
    this.hiddenTarget.dispatchEvent(new Event("input", { bubbles: true }))
  }
}
