import { Controller } from "@hotwired/stimulus"

// Closes a <details> dropdown on an outside click or Escape.
export default class extends Controller {
  connect() {
    this.closeOutside = (e) => {
      if (!this.element.contains(e.target)) this.element.open = false
    }
    this.closeOnEscape = (e) => {
      if (e.key === "Escape") this.element.open = false
    }
    document.addEventListener("click", this.closeOutside)
    document.addEventListener("keydown", this.closeOnEscape)
  }

  disconnect() {
    document.removeEventListener("click", this.closeOutside)
    document.removeEventListener("keydown", this.closeOnEscape)
  }
}
