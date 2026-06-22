import { Controller } from "@hotwired/stimulus"

// Auto-saving switch: submit the enclosing form the moment the checkbox flips,
// so a toggle persists without a submit button. The form's Turbo Stream
// response re-renders the control in the server's confirmed state.
export default class extends Controller {
  submit() {
    this.element.closest("form").requestSubmit()
  }
}
