const RULES = {
  "includes-any": (values, list) => values.some((value) => list.includes(value)),
  "excludes-all": (values, list) => values.length > 0 && !values.some((value) => list.includes(value)),
  "exactly-one": (values) => values.length === 1
}

export function warningApplies(rule, values, list) {
  return RULES[rule](values, list)
}

export function watchedValues(form, names) {
  return Array.from(form.elements)
    .filter((element) => names.includes(element.name))
    .flatMap(valuesOf)
}

function valuesOf(element) {
  if (element.selectedOptions) {
    return Array.from(element.selectedOptions, (option) => option.value).filter(Boolean)
  }
  if (element.type === "checkbox") return element.checked ? [element.value] : []
  return []
}
