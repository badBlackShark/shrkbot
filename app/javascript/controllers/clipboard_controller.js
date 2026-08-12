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
    this.pin(bubble)
    this.announce(label)
    this.restore = () => {
      clearTimeout(this.timer)
      bubble.textContent = original
      this.unpin(bubble)
      this.announce("")
      this.restore = null
    }
    this.timer = setTimeout(() => this.restore?.(), FLASH_MS)
  }

  pin(bubble) {
    bubble.style.visibility = "visible"
    bubble.style.opacity = "1"
  }

  unpin(bubble) {
    bubble.style.visibility = ""
    bubble.style.opacity = ""
  }

  announce(label) {
    if (this.hasAnnouncerTarget) this.announcerTarget.textContent = label
  }
}
