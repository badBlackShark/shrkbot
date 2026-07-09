import { Controller } from "@hotwired/stimulus"
import TomSelect from "tom-select"

export default class extends Controller {
  static values = { placeholder: String, prefix: String, colorDots: Boolean, lockIcon: String, create: Boolean }

  connect() {
    this.select = new TomSelect(this.element, {
      placeholder: this.placeholderValue || undefined,
      allowEmptyOption: false,
      maxOptions: null,
      plugins: this.plugins(),
      render: this.renderers(),
      create: this.createValue || false,
      persist: this.createValue ? false : undefined
    })
  }

  plugins() {
    if (this.createValue) return ["remove_button"]
    return this.colorDotsValue ? ["dropdown_input", "remove_button"] : ["dropdown_input", "clear_button"]
  }

  renderers() {
    if (this.colorDotsValue) return this.roleRenderers()
    if (this.prefixValue) return this.prefixRenderers()
    return {}
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

  roleRenderers() {
    const row = (data, escape) => {
      const dot = data.color ? `<span class="ts-dot" style="background:${escape(data.color)}"></span>` : ""
      const lock = data.reason ? `<span class="ts-lock" title="${escape(data.reason)}">${this.lockIconValue}</span>` : ""
      return `<div title="${data.reason ? escape(data.reason) : ""}">${dot}${escape(data.text)}${lock}</div>`
    }
    return { option: row, item: row }
  }

  disconnect() {
    this.select?.destroy()
  }
}
