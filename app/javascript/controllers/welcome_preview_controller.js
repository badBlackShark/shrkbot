import { Controller } from "@hotwired/stimulus"
import { text, pill, hint, nodes } from "lib/token_preview"

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

    for (const node of nodes(input.value, TOKEN, (match) => [this.token(match[1], kind)])) {
      output.append(node)
    }
  }

  token(name, kind) {
    if (name !== "user") return text(SAMPLE[name])
    if (kind === "join") return pill(`@${SAMPLE.username}`)

    return text(`@${SAMPLE.username}`)
  }
}
