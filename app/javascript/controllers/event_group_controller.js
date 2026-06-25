import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["all", "event", "count"]

  connect() {
    this.refresh()
  }

  toggleAll() {
    this.eventTargets.forEach((checkbox) => {
      checkbox.checked = this.allTarget.checked
    })
    this.refresh()
  }

  sync() {
    this.refresh()
  }

  refresh() {
    const total = this.eventTargets.length
    const enabled = this.eventTargets.filter((checkbox) => checkbox.checked).length
    this.allTarget.checked = enabled === total
    if (this.hasCountTarget) this.countTarget.textContent = `${enabled}/${total}`
  }
}
