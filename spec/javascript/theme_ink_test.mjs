import { test } from "node:test"
import assert from "node:assert/strict"

const { inkTheme } = await import("lib/theme_ink")

const TOKENS = { "--ease-exit": "cubic-bezier(.4, 0, 1, 1)", "--ease-standard": "cubic-bezier(.2, 0, 0, 1)" }
const TOGGLE = { getBoundingClientRect: () => ({ left: 1100, top: 14, width: 36, height: 36 }) }

function fakeEnv({ reducedMotion = false, registerProperty = () => {} } = {}) {
  const log = []
  const classes = new Set()
  const ink = {
    dataset: {},
    style: {},
    animate(keyframes, timing) {
      log.push({ step: "spread", background: this.style.background, keyframes, timing })
      return { finished: Promise.resolve() }
    },
    remove: () => log.push({ step: "remove" })
  }
  return {
    log,
    ink,
    classes,
    innerWidth: 1280,
    innerHeight: 900,
    CSS: { registerProperty },
    matchMedia: () => ({ matches: reducedMotion }),
    getComputedStyle: () => ({ getPropertyValue: (name) => TOKENS[name] }),
    document: {
      createElement: () => ink,
      body: { append: (element) => log.push({ step: "append", theme: element.dataset.theme, inking: classes.has("theme-inking") }) },
      documentElement: { classList: { add: (name) => classes.add(name), remove: (name) => classes.delete(name) } }
    }
  }
}

test("covers the page in the next theme's colour, applies the theme, then opens from the toggle", async () => {
  const env = fakeEnv()

  await inkTheme(TOGGLE, "dark", () => env.log.push({ step: "apply" }), env)

  const radius = `${Math.hypot(1118, 868)}px`
  assert.deepEqual(env.log, [
    { step: "append", theme: "dark", inking: true },
    {
      step: "spread",
      background: "radial-gradient(circle at 1118px 32px, var(--surface-page) var(--theme-ink), transparent calc(var(--theme-ink) + 1px))",
      keyframes: { "--theme-ink": ["0px", radius] },
      timing: { duration: 240, easing: "cubic-bezier(.4, 0, 1, 1)", fill: "forwards" }
    },
    { step: "apply" },
    {
      step: "spread",
      background: "radial-gradient(circle at 1118px 32px, transparent var(--theme-ink), var(--surface-page) calc(var(--theme-ink) + 1px))",
      keyframes: { "--theme-ink": ["0px", radius] },
      timing: { duration: 340, easing: "cubic-bezier(.2, 0, 0, 1)", fill: "forwards" }
    },
    { step: "remove" }
  ])
  assert.equal(env.classes.has("theme-inking"), false)
})

test("reduced motion applies the theme with no ink", async () => {
  const env = fakeEnv({ reducedMotion: true })

  await inkTheme(TOGGLE, "dark", () => env.log.push({ step: "apply" }), env)

  assert.deepEqual(env.log, [{ step: "apply" }])
})

test("a browser that cannot animate a registered property applies the theme with no ink", async () => {
  const env = fakeEnv({ registerProperty: null })

  await inkTheme(TOGGLE, "dark", () => env.log.push({ step: "apply" }), env)

  assert.deepEqual(env.log, [{ step: "apply" }])
})

test("an interrupted ink still clears itself", async () => {
  const env = fakeEnv()
  env.ink.animate = () => ({ finished: Promise.reject(new Error("AbortError")) })

  await assert.rejects(inkTheme(TOGGLE, "dark", () => {}, env))

  assert.deepEqual(env.log.at(-1), { step: "remove" })
  assert.equal(env.classes.has("theme-inking"), false)
})
