import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  toggle() {
    const apply = () => {
      const dark = document.documentElement.dataset.theme !== "dark"
      document.documentElement.dataset.theme = dark ? "dark" : "light"
      localStorage.setItem("shrk-theme", dark ? "dark" : "light")
    }

    const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches
    if (document.startViewTransition && !reduce) {
      document.startViewTransition(apply)
    } else {
      apply()
    }
  }
}
