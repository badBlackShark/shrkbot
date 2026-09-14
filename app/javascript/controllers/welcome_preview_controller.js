import { Controller } from "@hotwired/stimulus"
import { text, pill, hint, nodes } from "lib/token_preview"
import { render as renderMarkdown } from "lib/discord_markdown_dom"

const SAMPLE = { username: "newmember", displayname: "New Member", membercount: "1,234" }
const TOKEN = /\{(user|username|displayname|membercount)\}/g

export default class extends Controller {
  static targets = ["joinMessage", "leaveMessage", "joinOutput", "leaveOutput"]

  connect() {
    this.render()
  }

  render() {
    this.paint(this.joinMessageTarget, this.joinOutputTarget, "join")
    this.paint(this.leaveMessageTarget, this.leaveOutputTarget, "leave")
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
