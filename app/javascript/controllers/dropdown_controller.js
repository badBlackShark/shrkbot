import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]

  connect() {
    if (this.element.open) this.menuTarget.classList.add("no-enter")

    this.closeOutside = (e) => {
      if (!this.element.contains(e.target)) this.close()
    }
    this.closeOnEscape = (e) => {
      if (e.key === "Escape") this.close()
    }
    document.addEventListener("click", this.closeOutside)
    document.addEventListener("keydown", this.closeOnEscape)
  }

  disconnect() {
    document.removeEventListener("click", this.closeOutside)
    document.removeEventListener("keydown", this.closeOnEscape)
  }

  toggle(event) {
    if (this.element.open) {
      event.preventDefault()
      this.close()
    }
  }

  close() {
    if (!this.element.open || this.closing) return

    this.closing = true
    const menu = this.menuTarget
    menu.classList.add("is-closing")
    const done = (event) => {
      if (event.animationName !== "menuLeave") return
      menu.removeEventListener("animationend", done)
      menu.classList.remove("is-closing")
      menu.classList.remove("no-enter")
      this.element.open = false
      this.closing = false
    }
    menu.addEventListener("animationend", done)
  }
}
