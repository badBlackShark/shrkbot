export function enableBlankOption(select, placeholder = "") {
  if (select.multiple) return false
  if (select.getAttribute("aria-required") === "true") return false

  const blank = select.querySelector('option[value=""]')
  if (!blank) return false

  if (!blank.textContent.trim()) blank.textContent = placeholder
  return true
}
