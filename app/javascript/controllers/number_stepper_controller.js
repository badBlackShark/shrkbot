import { Controller } from "@hotwired/stimulus"
import { baseValue, shownPlaceholder, syncReset, unitBounds } from "lib/number_stepper"

export default class extends Controller {
  static targets = ["input", "reset", "unit", "field"]
  static values = { min: Number, max: Number, default: Number, defaultUnit: Number, placeholder: Number }

  increment() {
    const current = parseInt(this.inputTarget.value, 10) || 0
    this.inputTarget.value = Math.min(current + 1, this.#bounds.max)
    this.#dispatch()
  }

  decrement() {
    const current = parseInt(this.inputTarget.value, 10) || 0
    this.inputTarget.value = Math.max(current - 1, this.#bounds.min)
    this.#dispatch()
  }

  reset() {
    if (this.hasUnitTarget) {
      this.unitTarget.tomselect.setValue(String(this.defaultUnitValue), true)
      this.#rescale()
    }
    this.inputTarget.value = this.defaultValue / this.#factor
    this.inputTarget.focus()
    this.#dispatch()
  }

  changeUnit() {
    this.#rescale()
    this.#dispatch()
  }

  sync() {
    if (this.hasFieldTarget) this.fieldTarget.value = baseValue(this.inputTarget.value, this.#factor)
    if (this.hasResetTarget) syncReset(this.resetTarget, this.inputTarget.value, this.defaultValue, this.#factor)
  }

  #rescale() {
    const { min, max } = this.#bounds
    this.inputTarget.min = min
    if (Number.isFinite(max)) this.inputTarget.max = max
    if (this.hasPlaceholderValue) this.inputTarget.placeholder = shownPlaceholder(this.placeholderValue, this.#factor)
  }

  get #bounds() {
    return unitBounds(this.minValue, this.hasMaxValue ? this.maxValue : Infinity, this.#factor)
  }

  get #factor() {
    return this.hasUnitTarget ? Number(this.unitTarget.value) : 1
  }

  #dispatch() {
    this.inputTarget.dispatchEvent(new Event("input", { bubbles: true }))
  }
}
