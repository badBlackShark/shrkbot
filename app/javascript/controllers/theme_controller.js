import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  toggle() {
    const dark = document.documentElement.dataset.theme !== "dark"
    document.documentElement.dataset.theme = dark ? "dark" : "light"
    localStorage.setItem("shrk-theme", dark ? "dark" : "light")
  }
}
