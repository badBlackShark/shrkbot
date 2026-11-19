import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "option"]
  static classes = ["active", "inactive"]

  select(event) {
    this.choose(event.currentTarget)
  }

  keydown(event) {
    if (event.altKey || event.ctrlKey || event.metaKey) return

    const target = this.targetFor(event.key, event.target)
    if (!target) return

    event.preventDefault()
    target.focus()
    this.choose(target)
  }

  choose(option) {
    const value = option.dataset.value
    if (this.inputTarget.value === value) return

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
    const count = options.length
    const current = options.indexOf(from)

    const index = {
      ArrowRight: (current + 1) % count,
      ArrowDown: (current + 1) % count,
      ArrowLeft: (current - 1 + count) % count,
      ArrowUp: (current - 1 + count) % count,
      Home: 0,
      End: count - 1,
    }[key]
    return options[index]
  }
}
