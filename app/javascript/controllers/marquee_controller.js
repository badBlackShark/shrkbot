import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  scroll(event) {
    event.preventDefault()

    const loop = this.element.scrollWidth / 2
    const next = this.element.scrollLeft + event.deltaY + event.deltaX

    this.element.scrollLeft = ((next % loop) + loop) % loop
  }
}
