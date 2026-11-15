import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { key: String }
  static targets = ["toggle", "chevron", "body"]

  connect() {
    this.#show(localStorage.getItem(this.keyValue) === "open")
  }

  sync() {
    this.#set(this.toggleTarget.checked)
  }

  flip() {
    this.#set(this.bodyTarget.hidden)
  }

  #set(open) {
    this.#show(open)
    localStorage.setItem(this.keyValue, open ? "open" : "closed")
  }

  #show(open) {
    this.bodyTarget.hidden = !open
    this.chevronTarget.setAttribute("aria-expanded", String(open))
  }
}
