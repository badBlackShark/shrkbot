import { Controller } from "@hotwired/stimulus"
import { Reveal } from "lib/reveal"

const INTERACTIVE = "a, button, input, label, select, textarea"

export default class extends Controller {
  static values = { key: String }

  connect() {
    this.reveal = new Reveal(this.element)
    if (!this.element.open && this.#stored === "open") this.element.open = true
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
