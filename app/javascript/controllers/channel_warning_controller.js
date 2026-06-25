import { Controller } from "@hotwired/stimulus"

// Shows the "visible to @everyone" warning the moment a public channel is
// picked, before saving. Tom Select mirrors the choice onto the underlying
// <select> and fires a bubbling change, which this catches.
export default class extends Controller {
  static targets = ["warning"]
  static values = { visibleIds: Array }

  update(event) {
    const visible = this.visibleIdsValue.includes(event.target.value)
    this.warningTarget.classList.toggle("hidden", !visible)
  }
}
