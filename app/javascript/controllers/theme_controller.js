import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  toggle() {
    const root = document.documentElement
    const dark = root.dataset.theme !== "dark"
    const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches

    if (!reduce) {
      root.classList.add("theme-switching")
      setTimeout(() => root.classList.remove("theme-switching"), 300)
    }

    root.dataset.theme = dark ? "dark" : "light"
    localStorage.setItem("shrk-theme", dark ? "dark" : "light")
  }
}
