import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]
  static values = { min: Number, max: Number }

  increment() {
    const current = parseInt(this.inputTarget.value, 10) || 0
    const next = current + 1
    const cap = this.hasMaxValue ? this.maxValue : Infinity
    this.inputTarget.value = Math.min(next, cap)
    this.#dispatch()
  }

  decrement() {
    const current = parseInt(this.inputTarget.value, 10) || 0
    const next = current - 1
    this.inputTarget.value = Math.max(next, this.minValue)
    this.#dispatch()
  }

  #dispatch() {
    this.inputTarget.dispatchEvent(new Event("input", { bubbles: true }))
  }
}
