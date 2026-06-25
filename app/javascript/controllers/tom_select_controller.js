import { Controller } from "@hotwired/stimulus"
import TomSelect from "tom-select"

export default class extends Controller {
  static values = { placeholder: String }

  connect() {
    this.select = new TomSelect(this.element, {
      placeholder: this.placeholderValue || undefined,
      allowEmptyOption: false,
      maxOptions: null,
      plugins: ["dropdown_input"]
    })
  }

  disconnect() {
    this.select?.destroy()
  }
}
