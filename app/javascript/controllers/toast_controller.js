import { Controller } from "@hotwired/stimulus"
import { milliseconds } from "lib/motion"

export default class extends Controller {
  static values = { sticky: Boolean }

  connect() {
    if (this.stickyValue) return

    this.timeout = setTimeout(() => this.dismiss(), 5000)
  }

  disconnect() {
    clearTimeout(this.timeout)
    clearTimeout(this.fallback)
  }

  dismiss() {
    this.element.classList.add("toast-leave")
    this.element.addEventListener("animationend", this.#collapseAfterLeave)
  }

  #collapseAfterLeave = ({ animationName }) => {
    if (animationName !== "toastLeave") return

    const toast = this.element
    toast.removeEventListener("animationend", this.#collapseAfterLeave)
    toast.classList.add("toast-collapse")
    const remove = ({ propertyName }) => {
      if (propertyName === "grid-template-rows") toast.remove()
    }
    toast.addEventListener("transitionend", remove)
    toast.addEventListener("transitioncancel", remove)
    this.fallback = setTimeout(() => toast.remove(), milliseconds("--dur-slow"))
  }
}
