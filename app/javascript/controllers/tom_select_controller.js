import { Controller } from "@hotwired/stimulus"
import TomSelect from "tom-select"
import { enableBlankOption } from "lib/blank_option"
import { categoryOptions } from "lib/category_options"
import { noResultsHtml } from "lib/no_results"

export default class extends Controller {
  static values = { placeholder: String, prefix: String, colorDots: Boolean, lockIcon: String, create: Boolean, searchUrl: String, searchFailed: String, maxItems: Number }

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
      maxItems: this.maxItemsValue || null,
      searchField: [],
      score: () => () => 1,
      loadThrottle: 300,
      shouldLoad: (query) => query.trim().length > 0,
      load: (query, callback) => {
        this.select.clearOptions()
        fetch(`${url}?query=${encodeURIComponent(query)}`, { headers: { Accept: "application/json" } })
          .then((response) => {
            this.searchFailed = !response.ok
            return response.ok ? response.json() : []
          })
          .then((json) => callback(query === this.select.inputValue() ? categoryOptions(json) : []))
          .catch(() => {
            this.searchFailed = true
            callback()
          })
      }
    }
  }

  plugins() {
    if (this.createValue || this.searchUrlValue) return ["remove_button"]
    const removal = this.element.multiple ? "remove_button" : "clear_button"
    return ["dropdown_input", removal]
  }

  renderers() {
    if (this.searchUrlValue) return this.searchRenderers()
    if (this.colorDotsValue) return this.roleRenderers()
    if (this.prefixValue) return this.prefixRenderers()
    return {}
  }

  searchRenderers() {
    return {
      no_results: (_data, escape) => noResultsHtml({ failed: this.searchFailed, failureText: this.searchFailedValue, escape })
    }
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
