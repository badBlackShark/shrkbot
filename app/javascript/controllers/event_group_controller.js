import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["all", "event"]

  toggleAll() {
    this.eventTargets.forEach((checkbox) => {
      checkbox.checked = this.allTarget.checked
    })
  }

  sync() {
    this.allTarget.checked = this.eventTargets.every((checkbox) => checkbox.checked)
  }
}
