import { Controller } from "@hotwired/stimulus"
import { text, pill, hint, nodes } from "lib/token_preview"
import { render as renderMarkdown } from "lib/discord_markdown_dom"
import { syncResetButton, resetToDefault } from "lib/reset_to_default"

const SAMPLE = { username: "newmember", displayname: "New Member", membercount: "1,234" }
const TOKEN = /\{(user|username|displayname|membercount)\}/g
const KINDS = ["join", "leave"]

export default class extends Controller {
  static targets = ["joinMessage", "leaveMessage", "joinOutput", "leaveOutput", "joinReset", "leaveReset"]

  connect() {
    this.render()
  }

  render() {
    KINDS.forEach((kind) => {
      const input = this[`${kind}MessageTarget`]
      this.paint(input, this[`${kind}OutputTarget`], kind)
      syncResetButton(this[`${kind}ResetTarget`], input, input.dataset.default)
    })
  }

  reset({ params: { kind } }) {
    const input = this[`${kind}MessageTarget`]
    resetToDefault(input, input.dataset.default)
  }

  paint(input, output, kind) {
    output.replaceChildren()

    if (!input.value.trim()) {
      output.append(hint(output.dataset.emptyHint))
      return
    }

    output.append(...renderMarkdown(input.value, (leaf) => nodes(leaf, TOKEN, (match) => [this.token(match[1], kind)])))
  }

  token(name, kind) {
    if (name !== "user") return text(SAMPLE[name])
    if (kind === "join") return pill(`@${SAMPLE.username}`)

    return text(`@${SAMPLE.username}`)
  }
}
