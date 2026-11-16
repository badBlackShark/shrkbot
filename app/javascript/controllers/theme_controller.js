import { Controller } from "@hotwired/stimulus"
import { inkTheme } from "lib/theme_ink"

export default class extends Controller {
  toggle() {
    const root = document.documentElement
    const theme = root.dataset.theme === "dark" ? "light" : "dark"
    inkTheme(this.element, theme, () => {
      root.dataset.theme = theme
      localStorage.setItem("shrk-theme", theme)
    })
  }
}
