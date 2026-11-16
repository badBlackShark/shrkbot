import { milliseconds, token } from "lib/motion"

const REDUCED_MOTION = "(prefers-reduced-motion: reduce)"

export class Reveal {
  constructor(details, env = window) {
    this.details = details
    this.env = env
  }

  toggle() {
    return this.set(!this.#destination)
  }

  set(open) {
    if (open === this.#destination) return open

    if (this.env.matchMedia(REDUCED_MOTION).matches) {
      this.details.open = open
      return open
    }

    this.animation ||= this.#animation(open)
    this.opening = open
    this.details.toggleAttribute("data-closing", !open)
    this.animation.playbackRate = open ? 1 : -milliseconds("--dur-base", this.env) / milliseconds("--dur-fast", this.env)
    this.animation.play()
    return open
  }

  get #destination() {
    return this.animation ? this.opening : this.details.open
  }

  #animation(open) {
    const { details, env } = this
    const closed = details.querySelector(":scope > summary").offsetHeight + details.offsetHeight - details.clientHeight
    if (open) details.open = true

    const animation = new env.Animation(new env.KeyframeEffect(
      details,
      { height: [`${closed}px`, `${details.offsetHeight}px`] },
      { duration: milliseconds("--dur-base", env), easing: token("--ease-standard", env), fill: "both" }
    ))
    details.style.overflow = "clip"
    animation.onfinish = () => this.#settle()
    return animation
  }

  #settle() {
    if (!this.opening) this.details.open = false
    this.details.removeAttribute("data-closing")
    this.details.style.overflow = ""
    this.animation.cancel()
    this.animation = null
  }
}
