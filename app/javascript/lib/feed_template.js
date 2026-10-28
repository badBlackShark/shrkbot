export function tokenPattern(tokens) {
  return new RegExp(`\\{(${Object.keys(tokens).join("|")})\\}`, "g")
}
