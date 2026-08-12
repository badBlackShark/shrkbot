import { Controller } from "@hotwired/stimulus"

const FLASH_MS = 1200

export default class extends Controller {
  static targets = ["announcer"]
  static values = { copiedLabel: String, failedLabel: String }

  copy({ params: { text }, currentTarget }) {
    const bubble = currentTarget.parentElement.querySelector("[role=tooltip]")
    const written = navigator.clipboard?.writeText(text) ?? Promise.reject()

    written.then(
      () => this.flash(bubble, this.copiedLabelValue),
      () => this.flash(bubble, this.failedLabelValue)
    )
  }

  flash(bubble, label) {
    if (!bubble) return

    this.restore?.()
    const original = bubble.textContent
    bubble.textContent = label
    this.announce(label)
    this.restore = () => {
      clearTimeout(this.timer)
      bubble.textContent = original
      this.announce("")
      this.restore = null
    }
    this.timer = setTimeout(() => this.restore?.(), FLASH_MS)
  }

  announce(label) {
    if (this.hasAnnouncerTarget) this.announcerTarget.textContent = label
  }
}
