import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["bar", "discardedToast"]

  connect() {
    this.baseline = this.snapshot()
    this.dirty = false
    this.blockVisit = (event) => {
      if (!this.dirty) return
      event.preventDefault()
      this.shake()
    }
    this.warnUnload = (event) => {
      if (!this.dirty) return
      event.preventDefault()
      event.returnValue = ""
    }
    document.addEventListener("turbo:before-visit", this.blockVisit)
    window.addEventListener("beforeunload", this.warnUnload)
  }

  disconnect() {
    document.removeEventListener("turbo:before-visit", this.blockVisit)
    window.removeEventListener("beforeunload", this.warnUnload)
  }

  check() {
    this.setDirty(this.snapshot() !== this.baseline)
  }

  saved(event) {
    if (!event.detail.success) return // a 422 means validation failed — stay dirty

    requestAnimationFrame(() => {
      this.baseline = this.snapshot()
      this.setDirty(false)
    })
  }

  discard(event) {
    event.preventDefault()
    this.element.reset() // restores saved values in place; tom-select + enable-gate repaint on the reset event
    this.baseline = this.snapshot()
    this.setDirty(false)
    this.showDiscardedToast()
  }

  showDiscardedToast() {
    if (!this.hasDiscardedToastTarget) return

    document.getElementById("toasts")?.append(this.discardedToastTarget.content.cloneNode(true))
  }

  setDirty(value) {
    if (value === this.dirty) return
    this.dirty = value
    value ? this.reveal() : this.hide()
  }

  reveal() {
    this.barTarget.classList.remove("hidden", "save-bar-out")
    if (this.reduceMotion) return

    this.barTarget.classList.add("save-bar-anim")
    this.barTarget.addEventListener(
      "animationend",
      () => this.barTarget.classList.remove("save-bar-anim"),
      {once: true}
    )
  }

  hide() {
    if (this.barTarget.classList.contains("hidden")) return
    if (this.reduceMotion) {
      this.barTarget.classList.add("hidden")
      return
    }

    this.barTarget.classList.remove("save-bar-anim")
    this.barTarget.classList.add("save-bar-out")
    this.barTarget.addEventListener(
      "animationend",
      () => {
        this.barTarget.classList.add("hidden")
        this.barTarget.classList.remove("save-bar-out")
      },
      {once: true}
    )
  }

  shake() {
    if (this.reduceMotion) return

    const bar = this.barTarget
    if (this.ringEnd) bar.removeEventListener("animationend", this.ringEnd)
    bar.classList.remove("save-bar-blocked")
    void bar.offsetWidth // reflow so the animation restarts cleanly
    bar.classList.add("save-bar-blocked")
    this.ringEnd = (event) => {
      if (event.animationName !== "saveBarRingFade") return // wait for the longer ring-fade
      bar.classList.remove("save-bar-blocked")
      bar.removeEventListener("animationend", this.ringEnd)
      this.ringEnd = null
    }
    bar.addEventListener("animationend", this.ringEnd)
  }

  snapshot() {
    return new URLSearchParams(new FormData(this.element)).toString()
  }

  get reduceMotion() {
    return window.matchMedia("(prefers-reduced-motion: reduce)").matches
  }
}
