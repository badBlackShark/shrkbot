import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  submit() {
    // requestSubmit (not submit) fires the submit event so Turbo intercepts it
    // and the flip saves in place instead of doing a full-page navigation.
    // element.form also honors a form="" attribute, which closest() would miss.
    this.element.form.requestSubmit()
  }
}
