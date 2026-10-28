import { Controller } from "@hotwired/stimulus"
import { text, pill, hint, nodes } from "lib/token_preview"
import { render as renderMarkdown } from "lib/discord_markdown_dom"
import { isEmpty, tokenPattern } from "lib/feed_template"

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
    const tokens = JSON.parse(input.dataset.tokens)

    output.replaceChildren()

    if (isEmpty(template, tokens, JSON.parse(input.dataset.optionalTokens))) {
      output.append(hint(output.dataset.emptyHint))
      return
    }

    const blocks = renderMarkdown(template, (leaf) => nodes(leaf, tokenPattern(tokens), (match) => [text(tokens[match[1]])]))
    this.prependRoleMention(blocks[0])
    output.append(...blocks)
  }

  prependRoleMention(block) {
    const role = this.roleName()
    if (role) block.prepend(pill(`@${role}`), text(" "))
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
