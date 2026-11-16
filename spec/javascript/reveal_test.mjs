import { test } from "node:test"
import assert from "node:assert/strict"

const { Reveal } = await import("lib/reveal")

const TOKENS = { "--dur-base": ".18s", "--dur-fast": ".12s", "--ease-standard": " cubic-bezier(.2, 0, 0, 1)" }

function fakeDetails({ open }) {
  const attributes = new Set()
  return {
    open,
    style: { overflow: "" },
    get offsetHeight() {
      return this.open ? 202 : 46
    },
    get clientHeight() {
      return this.offsetHeight - 2
    },
    querySelector: () => ({ offsetHeight: 44 }),
    toggleAttribute: (name, on) => (on ? attributes.add(name) : attributes.delete(name)),
    removeAttribute: (name) => attributes.delete(name),
    hasAttribute: (name) => attributes.has(name)
  }
}

function fakeEnv({ reducedMotion = false } = {}) {
  const env = {
    animations: [],
    document: { documentElement: {} },
    matchMedia: () => ({ matches: reducedMotion }),
    getComputedStyle: () => ({ getPropertyValue: (name) => TOKENS[name] }),
    KeyframeEffect: class {
      constructor(target, keyframes, timing) {
        Object.assign(this, { target, keyframes, timing })
      }
    },
    Animation: class {
      constructor(effect) {
        this.effect = effect
        this.plays = 0
        this.cancelled = false
        env.animations.push(this)
      }

      play() {
        this.plays += 1
      }

      cancel() {
        this.cancelled = true
      }
    }
  }
  return env
}

function reveal(options, envOptions) {
  const details = fakeDetails(options)
  const env = fakeEnv(envOptions)
  return { details, env, reveal: new Reveal(details, env) }
}

test("opening shows the content first, then grows from the summary to the full height", () => {
  const { details, env, reveal: subject } = reveal({ open: false })

  assert.equal(subject.toggle(), true)

  const [animation] = env.animations
  assert.equal(details.open, true)
  assert.deepEqual(animation.effect.keyframes, { height: ["46px", "202px"] })
  assert.deepEqual(animation.effect.timing, { duration: 180, easing: "cubic-bezier(.2, 0, 0, 1)", fill: "both" })
  assert.equal(animation.playbackRate, 1)
  assert.equal(details.style.overflow, "clip")
  assert.equal(details.hasAttribute("data-closing"), false)
})

test("an opened section is left open and unclipped once the animation ends", () => {
  const { details, env, reveal: subject } = reveal({ open: false })
  subject.toggle()

  env.animations[0].onfinish()

  assert.equal(details.open, true)
  assert.equal(details.style.overflow, "")
  assert.equal(env.animations[0].cancelled, true)
})

test("closing plays the same animation backwards, faster, and keeps the content until it ends", () => {
  const { details, env, reveal: subject } = reveal({ open: true })

  assert.equal(subject.toggle(), false)

  const [animation] = env.animations
  assert.deepEqual(animation.effect.keyframes, { height: ["46px", "202px"] })
  assert.equal(animation.playbackRate, -1.5)
  assert.equal(details.open, true)
  assert.equal(details.hasAttribute("data-closing"), true)

  animation.onfinish()

  assert.equal(details.open, false)
  assert.equal(details.hasAttribute("data-closing"), false)
})

test("a second click mid-flight turns the running animation around", () => {
  const { details, env, reveal: subject } = reveal({ open: true })
  subject.toggle()

  assert.equal(subject.toggle(), true)

  assert.equal(env.animations.length, 1)
  assert.equal(env.animations[0].playbackRate, 1)
  assert.equal(env.animations[0].plays, 2)
  assert.equal(details.hasAttribute("data-closing"), false)

  env.animations[0].onfinish()

  assert.equal(details.open, true)
})

test("a section that has settled starts a fresh animation on the next toggle", () => {
  const { env, reveal: subject } = reveal({ open: true })
  subject.toggle()
  env.animations[0].onfinish()

  subject.toggle()

  assert.equal(env.animations.length, 2)
  assert.deepEqual(env.animations[1].effect.keyframes, { height: ["46px", "202px"] })
})

test("settling early lands a closing section where the animation would have", () => {
  const { details, env, reveal: subject } = reveal({ open: true })
  subject.toggle()

  subject.settle()

  assert.equal(details.open, false)
  assert.equal(details.hasAttribute("data-closing"), false)
  assert.equal(details.style.overflow, "")
  assert.equal(env.animations[0].cancelled, true)
})

test("settling a section at rest changes nothing", () => {
  const { details, reveal: subject } = reveal({ open: true })

  subject.settle()

  assert.equal(details.open, true)
})

test("set does nothing when the section is already heading that way", () => {
  const { env, reveal: subject } = reveal({ open: false })
  subject.set(true)

  assert.equal(subject.set(true), true)
  assert.equal(env.animations[0].plays, 1)
})

test("reduced motion toggles the section with no animation", () => {
  const { details, env, reveal: subject } = reveal({ open: false }, { reducedMotion: true })

  assert.equal(subject.toggle(), true)

  assert.equal(details.open, true)
  assert.equal(env.animations.length, 0)
})
