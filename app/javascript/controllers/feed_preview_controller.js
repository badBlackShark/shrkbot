import { Controller } from "@hotwired/stimulus"
import { text, pill, nodes } from "lib/token_preview"
import { render as renderMarkdown } from "lib/discord_markdown_dom"
import { tokenPattern } from "lib/feed_template"

export default class extends Controller {
  static targets = ["template", "output", "role"]

  connect() {
    this.render()
  }

  render() {
    this.templateTargets.forEach((input) => this.paint(input, this.outputFor(input)))
  }

  paint(input, output) {
    const template = input.value.trim()
    const tokens = JSON.parse(input.dataset.tokens)
    const blocks = template ? renderMarkdown(template, (leaf) => nodes(leaf, tokenPattern(tokens), (match) => [text(tokens[match[1]])])) : []
    const role = this.roleName()

    if (role) {
      if (blocks.length === 0) blocks.push(document.createElement("p"))
      blocks[0].prepend(pill(`@${role}`), text(" "))
    }

    output.replaceChildren(...blocks)
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
