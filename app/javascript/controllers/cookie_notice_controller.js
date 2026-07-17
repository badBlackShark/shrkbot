import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    if (document.cookie.includes("shrk-cookie-notice=")) return

    this.element.hidden = false
  }

  dismiss() {
    document.cookie = "shrk-cookie-notice=seen; max-age=31536000; path=/; samesite=lax"
    this.element.hidden = true
  }
}
