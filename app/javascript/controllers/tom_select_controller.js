import { Controller } from "@hotwired/stimulus"
import TomSelect from "tom-select"

const LOCK_SVG = `<svg viewBox="0 0 256 256" fill="currentColor" aria-hidden="true"><path d="M208 80h-32V56a48 48 0 0 0-96 0v24H48a16 16 0 0 0-16 16v112a16 16 0 0 0 16 16h160a16 16 0 0 0 16-16V96a16 16 0 0 0-16-16ZM96 56a32 32 0 0 1 64 0v24H96Zm112 152H48V96h160z"/></svg>`

export default class extends Controller {
  static values = { placeholder: String, prefix: String, colorDots: Boolean }

  connect() {
    this.select = new TomSelect(this.element, {
      placeholder: this.placeholderValue || undefined,
      allowEmptyOption: false,
      maxOptions: null,
      plugins: ["dropdown_input"],
      render: this.renderers()
    })
    // a form reset restores the <select> but not Tom Select's UI; re-sync once it settles
    this.form = this.element.form
    this.onReset = () => requestAnimationFrame(() => this.select?.sync())
    this.form?.addEventListener("reset", this.onReset)
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
      const lock = data.reason ? `<span class="ts-lock" title="${escape(data.reason)}">${LOCK_SVG}</span>` : ""
      return `<div title="${data.reason ? escape(data.reason) : ""}">${dot}${escape(data.text)}${lock}</div>`
    }
    return { option: row, item: row }
  }

  disconnect() {
    this.form?.removeEventListener("reset", this.onReset)
    this.select?.destroy()
  }
}
