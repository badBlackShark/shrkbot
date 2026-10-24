import { Controller } from "@hotwired/stimulus"
import { text, pill, hint, nodes } from "lib/token_preview"
import { render as renderMarkdown } from "lib/discord_markdown_dom"
import { subjectText, tokenPattern } from "lib/feed_template"

export default class extends Controller {
  static targets = ["template", "output", "role"]

  connect() {
    this.render()
  }

  render() {
    this.templateTargets.forEach((input) => this.paint(input, this.outputFor(input)))
  }

  reset(event) {
    const input = event.target.closest("[data-feed-preview-field]").querySelector("textarea")
    input.value = input.placeholder
    input.dispatchEvent(new Event("input", { bubbles: true }))
  }

  paint(input, output) {
    const template = input.value.trim() || input.placeholder
    const tokens = { ...JSON.parse(input.dataset.tokens), role: this.roleName() }

    output.replaceChildren()

    if (!subjectText(template, tokens)) {
      output.append(hint(output.dataset.emptyHint))
      return
    }

    output.append(...renderMarkdown(template, (leaf) => nodes(leaf, tokenPattern(tokens), (match) => [this.token(match[1], tokens)])))
  }

  token(name, tokens) {
    if (name === "role") return tokens.role ? pill(`@${tokens.role}`) : text("")

    return text(tokens[name])
  }

  outputFor(input) {
    const field = input.closest("[data-feed-preview-field]")
    return this.outputTargets.find((output) => field.contains(output))
  }

  roleName() {
    if (!this.hasRoleTarget) return ""

    const selected = this.roleTarget.selectedOptions[0]
    return selected && selected.value ? selected.text : ""
  }
}
