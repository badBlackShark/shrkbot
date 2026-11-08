import { Controller } from "@hotwired/stimulus"
import TomSelect from "tom-select"
import { enableBlankOption } from "lib/blank_option"
import { categoryOptions } from "lib/category_options"

export default class extends Controller {
  static values = { placeholder: String, prefix: String, colorDots: Boolean, lockIcon: String, create: Boolean, searchUrl: String }

  connect() {
    this.select = new TomSelect(this.element, {
      placeholder: this.placeholderValue || undefined,
      allowEmptyOption: enableBlankOption(this.element, this.placeholderValue),
      maxOptions: null,
      plugins: this.plugins(),
      render: this.renderers(),
      create: this.createValue || false,
      persist: this.createValue ? false : undefined,
      ...this.remoteSearch()
    })
  }

  remoteSearch() {
    if (!this.searchUrlValue) return {}
    const url = this.searchUrlValue
    return {
      valueField: "value",
      labelField: "text",
      searchField: [],
      score: () => () => 1,
      loadThrottle: 300,
      shouldLoad: (query) => query.trim().length > 0,
      load: (query, callback) => {
        fetch(`${url}?query=${encodeURIComponent(query)}`, { headers: { Accept: "application/json" } })
          .then((response) => (response.ok ? response.json() : []))
          .then((json) => callback(categoryOptions(json)))
          .catch(() => callback())
      }
    }
  }

  plugins() {
    if (this.createValue || this.searchUrlValue) return ["remove_button"]
    const removal = this.element.multiple ? "remove_button" : "clear_button"
    return ["dropdown_input", removal]
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
