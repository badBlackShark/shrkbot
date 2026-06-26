import { Controller } from "@hotwired/stimulus"
import TomSelect from "tom-select"

export default class extends Controller {
  static values = { placeholder: String, prefix: String }

  connect() {
    this.select = new TomSelect(this.element, {
      placeholder: this.placeholderValue || undefined,
      allowEmptyOption: false,
      maxOptions: null,
      plugins: ["dropdown_input"],
      render: this.prefixValue ? this.prefixRenderers() : {}
    })
    // a form reset restores the <select> but not Tom Select's UI; re-sync once it settles
    this.form = this.element.form
    this.onReset = () => requestAnimationFrame(() => this.select?.sync())
    this.form?.addEventListener("reset", this.onReset)
  }

  prefixRenderers() {
    const prefix = this.prefixValue
    const row = (data, escape) => {
      const label = escape(data.text)
      if (!data.value) return `<div>${label}</div>`
      return `<div><span class="ts-prefix">${escape(prefix)}</span>${label}</div>`
    }
    return { option: row, item: row }
  }

  disconnect() {
    this.form?.removeEventListener("reset", this.onReset)
    this.select?.destroy()
  }
}
