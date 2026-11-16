import { test } from "node:test"
import assert from "node:assert/strict"

const { inkTheme } = await import("lib/theme_ink")

const TOKENS = { "--ease-exit": "cubic-bezier(.4, 0, 1, 1)", "--ease-standard": "cubic-bezier(.2, 0, 0, 1)" }
const TOGGLE = { getBoundingClientRect: () => ({ left: 1100, top: 14, width: 36, height: 36 }) }

function fakeEnv({ reducedMotion = false, registerProperty = () => {}, inking = false } = {}) {
  const log = []
  const classes = new Set(inking ? ["theme-inking"] : [])
  const ink = {
    dataset: {},
    style: {},
    animate(keyframes, timing) {
      log.push({ step: "spread", inking: classes.has("theme-inking"), background: this.style.background, keyframes, timing })
      return { finished: Promise.resolve() }
    },
    remove: () => log.push({ step: "remove" })
  }
  return {
    log,
    ink,
    classes,
    CSS: { registerProperty },
    matchMedia: () => ({ matches: reducedMotion }),
    getComputedStyle: () => ({ getPropertyValue: (name) => TOKENS[name] }),
    document: {
      createElement: () => ink,
      body: { append: (element) => log.push({ step: "append", ...element.dataset }) },
      documentElement: {
        clientWidth: 1280,
        clientHeight: 900,
        classList: { add: (name) => classes.add(name), remove: (name) => classes.delete(name), contains: (name) => classes.has(name) }
      }
    }
  }
}

test("covers the page in the next theme's colour, applies the theme, then opens from the toggle", async () => {
  const env = fakeEnv()

  await inkTheme(TOGGLE, "dark", () => env.log.push({ step: "apply" }), env)

  const radius = `${Math.hypot(1118, 868)}px`
  assert.deepEqual(env.log, [
    { step: "append", theme: "dark", turboTemporary: "" },
    {
      step: "spread",
      inking: true,
      background: "radial-gradient(circle at 1118px 32px, var(--surface-page) var(--theme-ink), transparent calc(var(--theme-ink) + 1px))",
      keyframes: { "--theme-ink": ["0px", radius] },
      timing: { duration: 240, easing: "cubic-bezier(.4, 0, 1, 1)", fill: "forwards" }
    },
    { step: "apply" },
    {
      step: "spread",
      inking: true,
      background: "radial-gradient(circle at 1118px 32px, transparent var(--theme-ink), var(--surface-page) calc(var(--theme-ink) + 1px))",
      keyframes: { "--theme-ink": ["0px", radius] },
      timing: { duration: 340, easing: "cubic-bezier(.2, 0, 0, 1)", fill: "forwards" }
    },
    { step: "remove" }
  ])
  assert.equal(env.classes.has("theme-inking"), false)
})

test("a switch that fails under the cover still takes the ink off the page", async () => {
  const env = fakeEnv()
  const blocked = new Error("storage is blocked")

  await assert.rejects(inkTheme(TOGGLE, "dark", () => { throw blocked }, env), blocked)

  assert.deepEqual(env.log.map(({ step }) => step), ["append", "spread", "remove"])
  assert.equal(env.classes.has("theme-inking"), false)
})

test("a click while the ink runs is ignored, on any page", async () => {
  const env = fakeEnv({ inking: true })

  await inkTheme(TOGGLE, "dark", () => env.log.push({ step: "apply" }), env)

  assert.deepEqual(env.log, [])
  assert.equal(env.classes.has("theme-inking"), true)
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
