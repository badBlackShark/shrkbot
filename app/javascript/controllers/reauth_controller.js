import { Controller } from "@hotwired/stimulus"

// Automatically re-runs the Discord OAuth request when a session's access token
// has expired, so the user is signed back in without having to click.
export default class extends Controller {
  connect() {
    this.element.requestSubmit()
  }
}
