import { Controller } from "@hotwired/stimulus"
import { syncReset } from "lib/number_stepper"

export default class extends Controller {
  static targets = ["input", "reset"]
  static values = { min: Number, max: Number, default: Number }

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

  reset() {
    this.inputTarget.value = this.defaultValue
    this.inputTarget.focus()
    this.#dispatch()
  }

  sync() {
    syncReset(this.resetTarget, this.inputTarget.value, this.defaultValue)
  }

  #dispatch() {
    this.inputTarget.dispatchEvent(new Event("input", { bubbles: true }))
  }
}
