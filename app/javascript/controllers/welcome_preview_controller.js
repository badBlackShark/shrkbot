import { Controller } from "@hotwired/stimulus"
import { text, pill, hint, nodes } from "lib/token_preview"
import { render as renderMarkdown } from "lib/discord_markdown_dom"

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
      this[`${kind}ResetTarget`].hidden = input.value === input.dataset.default
    })
  }

  reset({ params: { kind } }) {
    const input = this[`${kind}MessageTarget`]
    input.value = input.dataset.default
    input.dispatchEvent(new Event("input", { bubbles: true }))
    input.focus()
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
