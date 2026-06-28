import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "option"]
  static classes = ["active", "inactive"]

  select(event) {
    const value = event.currentTarget.dataset.value
    this.inputTarget.value = value
    this.optionTargets.forEach((option) => {
      const active = option.dataset.value === value
      option.setAttribute("aria-pressed", active)
      option.classList.remove(...(active ? this.inactiveClasses : this.activeClasses))
      option.classList.add(...(active ? this.activeClasses : this.inactiveClasses))
    })
    this.inputTarget.dispatchEvent(new Event("input", { bubbles: true }))
  }
}
