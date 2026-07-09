import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["duration", "banWarning"]

  connect() {
    this.update()
    this.element.addEventListener("input", this.onInput)
  }

  disconnect() {
    this.element.removeEventListener("input", this.onInput)
  }

  onInput = (event) => {
    if (event.target.type === "hidden" && event.target.closest("[data-controller~='segmented']")) {
      this.update()
    }
  }

  update() {
    const input = this.element.querySelector("[data-segmented-target='input']")
    if (!input) return

    const value = input.value
    if (this.hasDurationTarget) this.durationTarget.hidden = value !== "timeout"
    if (this.hasBanWarningTarget) this.banWarningTarget.hidden = value !== "ban"
  }
}
