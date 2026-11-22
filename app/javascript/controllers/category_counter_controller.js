import { Controller } from "@hotwired/stimulus"
import { countStreams, readFilters, sentence } from "lib/category_count"

export default class extends Controller {
  static values = { url: String, none: String, one: String, many: String, failed: String }

  async connect() {
    this.form = this.element.closest("form")
    this.form.addEventListener("input", this.render)
    this.form.addEventListener("change", this.render)
    this.rows = await this.load()
    this.render()
  }

  disconnect() {
    this.form.removeEventListener("input", this.render)
    this.form.removeEventListener("change", this.render)
  }

  async load() {
    try {
      const response = await fetch(this.urlValue, { headers: { Accept: "application/json" } })
      if (!response.ok) return null
      return await response.json()
    } catch {
      return null
    }
  }

  render = () => {
    if (this.rows === undefined) return
    if (this.rows === null) {
      this.element.textContent = this.failedValue
      return
    }
    const count = countStreams(this.rows, readFilters(this.form))
    this.element.textContent = sentence(count, { none: this.noneValue, one: this.oneValue, many: this.manyValue })
  }
}
