import { Controller } from "@hotwired/stimulus"
import TomSelect from "tom-select"

// The underlying <select> keeps its name and options, so the form submits the
// same value whether or not this enhancement runs.
export default class extends Controller {
  static values = { placeholder: String }

  connect() {
    this.select = new TomSelect(this.element, {
      placeholder: this.placeholderValue || undefined,
      allowEmptyOption: true,
      maxOptions: null
    })
  }

  disconnect() {
    this.select?.destroy()
  }
}
