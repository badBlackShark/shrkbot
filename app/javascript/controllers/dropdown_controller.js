import { Controller } from "@hotwired/stimulus"

// A <details> that animates open and closed. The panel fades in via CSS on
// [open]; closing is intercepted here so the exit animation can finish before
// the panel is removed. Wire it up as:
//   <details data-controller="dropdown">
//     <summary data-action="click->dropdown#toggle">…</summary>
//     <div data-dropdown-target="menu" class="dropdown-menu">…</div>
//   </details>
// A transient menu dismisses on outside-click/Escape (the default); a
// persistent disclosure (e.g. an accordion section) sets
// data-dropdown-dismiss-on-outside-value="false" so it only closes via its own
// summary.
export default class extends Controller {
  static targets = ["menu"]
  static values = {dismissOnOutside: {type: Boolean, default: true}}

  connect() {
    if (!this.dismissOnOutsideValue) return

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
    if (!this.closeOutside) return

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

    const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches
    if (reduce || !this.hasMenuTarget) {
      this.element.open = false
      return
    }

    this.closing = true
    const menu = this.menuTarget
    menu.classList.add("is-closing")
    const done = (event) => {
      if (event.animationName !== "menuLeave") return
      menu.removeEventListener("animationend", done)
      menu.classList.remove("is-closing")
      this.element.open = false
      this.closing = false
    }
    menu.addEventListener("animationend", done)
  }
}
