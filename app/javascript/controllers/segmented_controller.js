import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "option"]
  static classes = ["active", "inactive"]

  select(event) {
    this.choose(event.currentTarget)
  }

  keydown(event) {
    const target = this.targetFor(event.key, event.target)
    if (!target) return

    event.preventDefault()
    target.focus()
    this.choose(target)
  }

  choose(option) {
    const value = option.dataset.value
    this.inputTarget.value = value
    this.optionTargets.forEach((other) => {
      const active = other === option
      other.setAttribute("aria-checked", active)
      other.tabIndex = active ? 0 : -1
      other.classList.remove(...(active ? this.inactiveClasses : this.activeClasses))
      other.classList.add(...(active ? this.activeClasses : this.inactiveClasses))
    })
    this.inputTarget.dispatchEvent(new Event("input", { bubbles: true }))
  }

  targetFor(key, from) {
    const options = this.optionTargets
    const last = options.length - 1
    const current = options.indexOf(from)
    if (current < 0 && !["Home", "End"].includes(key)) return null

    const index = {
      ArrowRight: current === last ? 0 : current + 1,
      ArrowDown: current === last ? 0 : current + 1,
      ArrowLeft: current === 0 ? last : current - 1,
      ArrowUp: current === 0 ? last : current - 1,
      Home: 0,
      End: last,
    }[key]
    return options[index]
  }
}
