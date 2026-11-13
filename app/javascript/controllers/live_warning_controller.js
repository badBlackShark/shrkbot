import { Controller } from "@hotwired/stimulus"
import { warningApplies, watchedValues } from "lib/live_warning"

// Tom Select mirrors a pick onto the underlying <select> and fires a bubbling change.
export default class extends Controller {
  static values = { fields: Array, rule: String, list: Array }

  connect() {
    this.form = this.element.closest("form")
    this.form.addEventListener("change", this.update)
    this.update()
  }

  disconnect() {
    this.form.removeEventListener("change", this.update)
  }

  update = () => {
    const values = watchedValues(this.form, this.fieldsValue)
    this.element.hidden = !warningApplies(this.ruleValue, values, this.listValue)
  }
}
