import { Controller } from "@hotwired/stimulus"
import { showPanels } from "lib/option_panels"

export default class extends Controller {
  static targets = ["panel"]

  show(event) {
    showPanels(this.panelTargets, event.target.value)
  }
}
