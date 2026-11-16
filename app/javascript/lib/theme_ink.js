import { reducedMotion, token } from "lib/motion"

const COVER_MS = 240
const OPEN_MS = 340

export async function inkTheme(origin, theme, apply, env = window) {
  if (reducedMotion(env) || !env.CSS?.registerProperty) return apply()

  const { document } = env
  const { x, y, radius } = reach(origin, env)
  const ink = document.createElement("div")
  ink.className = "theme-ink"
  ink.dataset.theme = theme

  const paint = (inside, outside) => {
    ink.style.background = `radial-gradient(circle at ${x}px ${y}px, ${inside} var(--theme-ink), ${outside} calc(var(--theme-ink) + 1px))`
  }
  const spread = (duration, easing) => {
    return ink.animate({ "--theme-ink": ["0px", `${radius}px`] }, { duration, easing: token(easing, env), fill: "forwards" }).finished
  }

  document.documentElement.classList.add("theme-inking")
  paint("var(--surface-page)", "transparent")
  document.body.append(ink)
  try {
    await spread(COVER_MS, "--ease-exit")
    apply()
    paint("transparent", "var(--surface-page)")
    await spread(OPEN_MS, "--ease-standard")
  } finally {
    ink.remove()
    document.documentElement.classList.remove("theme-inking")
  }
}

function reach(origin, env) {
  const box = origin.getBoundingClientRect()
  const x = box.left + box.width / 2
  const y = box.top + box.height / 2
  return { x, y, radius: Math.hypot(Math.max(x, env.innerWidth - x), Math.max(y, env.innerHeight - y)) }
}
