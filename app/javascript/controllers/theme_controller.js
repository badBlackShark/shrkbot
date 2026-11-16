import { Controller } from "@hotwired/stimulus"
import { inkTheme } from "lib/theme_ink"

export default class extends Controller {
  async toggle() {
    if (this.switching) return

    const root = document.documentElement
    const theme = root.dataset.theme === "dark" ? "light" : "dark"
    this.switching = true
    try {
      await inkTheme(this.element, theme, () => {
        root.dataset.theme = theme
        localStorage.setItem("shrk-theme", theme)
      })
    } finally {
      this.switching = false
    }
  }
}
