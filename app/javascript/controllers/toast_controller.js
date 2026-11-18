import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { sticky: Boolean }

  connect() {
    if (this.stickyValue) return

    this.timeout = setTimeout(() => this.dismiss(), 5000)
  }

  disconnect() {
    clearTimeout(this.timeout)
  }

  dismiss() {
    this.element.classList.add("toast-leave")
    this.element.addEventListener("animationend", () => this.collapse(), { once: true })
  }

  collapse() {
    const toast = this.element
    toast.style.height = `${toast.offsetHeight}px`
    toast.getBoundingClientRect()
    toast.classList.add("toast-collapse")
    toast.style.height = "0px"
    toast.addEventListener("transitionend", ({ propertyName }) => {
      if (propertyName === "height") toast.remove()
    })
  }
}
