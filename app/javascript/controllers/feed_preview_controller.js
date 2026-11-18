import { Controller } from "@hotwired/stimulus"
import { text, pill, nodes } from "lib/token_preview"
import { render as renderMarkdown } from "lib/discord_markdown_dom"
import { tokenPattern, previewTemplate } from "lib/feed_template"
import { roleSelectFor, pingedRoleName } from "lib/role_scope"
import { syncResetButton, resetToDefault } from "lib/reset_to_default"

export default class extends Controller {
  static targets = ["template", "output", "role", "reset"]

  connect() {
    this.render()
  }

  render() {
    this.templateTargets.forEach((input) => this.paint(input, this.inField(input, this.outputTargets)))
    this.resetTargets.forEach((reset) => {
      const input = this.inField(reset, this.templateTargets)
      syncResetButton(reset, input, input.dataset.fallback)
    })
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
    const input = this.inField(event.currentTarget, this.templateTargets)
    resetToDefault(input, input.dataset.fallback)
  }

  inField(element, targets) {
    const field = element.closest("[data-feed-preview-field]")
    return targets.find((target) => field.contains(target))
  }

  roleName(input) {
    return pingedRoleName(roleSelectFor(input, this.roleTargets))
  }
}
