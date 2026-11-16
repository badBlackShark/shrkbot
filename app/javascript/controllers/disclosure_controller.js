import { Controller } from "@hotwired/stimulus"
import { Reveal } from "lib/reveal"

const INTERACTIVE = "a, button, input, label, select, textarea"

export default class extends Controller {
  static targets = ["details"]
  static values = { key: String }

  connect() {
    const details = this.hasDetailsTarget ? this.detailsTarget : this.element
    this.reveal = new Reveal(details)
    if (!details.open && this.#stored === "open") details.open = true
    this.settle = () => this.reveal.settle()
    document.addEventListener("turbo:before-cache", this.settle)
  }

  disconnect() {
    document.removeEventListener("turbo:before-cache", this.settle)
  }

  toggle(event) {
    if (event.target.closest(INTERACTIVE)) return

    event.preventDefault()
    this.#remember(this.reveal.toggle())
  }

  follow({ target }) {
    this.#remember(this.reveal.set(target.checked))
  }

  get #stored() {
    return this.hasKeyValue ? localStorage.getItem(this.keyValue) : null
  }

  #remember(open) {
    if (this.hasKeyValue) localStorage.setItem(this.keyValue, open ? "open" : "closed")
  }
}
