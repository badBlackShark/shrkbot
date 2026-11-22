const CHANNEL_URL = /^(?:https?:\/\/)?(?:(?:www|m)\.)?twitch\.tv\/([A-Za-z0-9_]+)/i
const MIN_VIEWERS = "subscription[min_viewers]"
const LANGUAGES = "subscription[languages][]"
const EXCLUDED = "subscription[excluded_channels][]"

export function normaliseLogin(value) {
  const text = String(value).trim()
  const match = text.match(CHANNEL_URL)
  return (match ? match[1] : text.replace(/^@/, "")).toLowerCase()
}

export function countStreams(rows, { minViewers, languages, excluded }) {
  const skipped = new Set(excluded.map(normaliseLogin))
  return rows.filter((row) => {
    if (row.viewers < minViewers) return false
    if (languages.length > 0 && !languages.includes(row.language)) return false
    return !skipped.has(row.login)
  }).length
}

export function readFilters(form) {
  const named = (name) => [...form.elements].filter((element) => element.name === name)
  const picked = (name) => named(name).flatMap((element) => [...(element.selectedOptions || [])].map((option) => option.value))
  const floor = named(MIN_VIEWERS)[0]
  return {
    minViewers: Number(floor?.value) || 0,
    languages: picked(LANGUAGES),
    excluded: picked(EXCLUDED)
  }
}

export function sentence(count, strings) {
  if (count === 0) return strings.none
  if (count === 1) return strings.one
  return strings.many.replace("{number}", count)
}
