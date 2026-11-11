import { Controller } from "@hotwired/stimulus"
import { text, pill, nodes } from "lib/token_preview"
import { render as renderMarkdown } from "lib/discord_markdown_dom"
import { tokenPattern, previewTemplate } from "lib/feed_template"
import { roleSelectFor } from "lib/role_scope"

export default class extends Controller {
  static targets = ["template", "output", "role"]

  connect() {
    this.render()
  }

  render() {
    this.templateTargets.forEach((input) => this.paint(input, this.outputFor(input)))
  }

  paint(input, output) {
    const tokens = JSON.parse(input.dataset.tokens)
    const template = previewTemplate(input.value.trim(), input.dataset.fallback, tokens).trim()
    const blocks = template ? renderMarkdown(template, (leaf) => nodes(leaf, tokenPattern(tokens), (match) => [text(tokens[match[1]])])) : []
    const role = this.roleName(input)

    if (role) {
      if (blocks.length === 0) blocks.push(document.createElement("p"))
      blocks[0].prepend(pill(`@${role}`), text(" "))
    }

    output.replaceChildren(...blocks)
  }

  reset(event) {
    const field = event.currentTarget.closest("[data-feed-preview-field]")
    const input = this.templateTargets.find((template) => field.contains(template))
    input.value = input.dataset.fallback
    input.dispatchEvent(new Event("input", { bubbles: true }))
  }

  outputFor(input) {
    const field = input.closest("[data-feed-preview-field]")
    return this.outputTargets.find((output) => field.contains(output))
  }

  roleName(input) {
    const select = roleSelectFor(input, this.roleTargets)
    const selected = select && select.selectedOptions[0]
    return selected && selected.value ? selected.text : ""
  }
}
