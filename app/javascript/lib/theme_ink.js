import { reducedMotion, token } from "lib/motion"

const COVER_MS = 240
const OPEN_MS = 340

export async function inkTheme(origin, theme, apply, env = window) {
  if (reducedMotion(env) || !env.CSS?.registerProperty) return apply()

  const { document } = env
  const root = document.documentElement
  if (root.classList.contains("theme-inking")) return

  const { x, y, radius } = reach(origin, root)
  const ink = document.createElement("div")
  ink.className = "theme-ink"
  ink.dataset.theme = theme
  ink.dataset.turboTemporary = ""

  const paint = (inside, outside) => {
    ink.style.background = `radial-gradient(circle at ${x}px ${y}px, ${inside} var(--theme-ink), ${outside} calc(var(--theme-ink) + 1px))`
  }
  const spread = (duration, easing) => {
    return ink.animate({ "--theme-ink": ["0px", `${radius}px`] }, { duration, easing: token(easing, env), fill: "forwards" }).finished
  }

  root.classList.add("theme-inking")
  paint("var(--surface-page)", "transparent")
  document.body.append(ink)
  try {
    await spread(COVER_MS, "--ease-exit")
    apply()
    paint("transparent", "var(--surface-page)")
    await spread(OPEN_MS, "--ease-standard")
  } finally {
    ink.remove()
    root.classList.remove("theme-inking")
  }
}

function reach(origin, { clientWidth, clientHeight }) {
  const box = origin.getBoundingClientRect()
  const x = box.left + box.width / 2
  const y = box.top + box.height / 2
  return { x, y, radius: Math.hypot(Math.max(x, clientWidth - x), Math.max(y, clientHeight - y)) }
}
