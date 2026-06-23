import { Controller } from "@hotwired/stimulus"

const SAMPLE = { user: "newmember", membercount: "1,234" }

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
      const hint = document.createElement("span")
      hint.className = "italic text-ink-500"
      hint.textContent = output.dataset.emptyHint
      output.append(hint)
      return
    }

    for (const node of this.nodes(input.value, kind)) output.append(node)
  }

  nodes(text, kind) {
    const out = []
    const pattern = /\{user\}|\{membercount\}/g
    let last = 0
    let match
    while ((match = pattern.exec(text))) {
      if (match.index > last) out.push(document.createTextNode(text.slice(last, match.index)))
      out.push(this.token(match[0], kind))
      last = pattern.lastIndex
    }
    if (last < text.length) out.push(document.createTextNode(text.slice(last)))
    return out
  }

  token(token, kind) {
    if (token === "{membercount}") return document.createTextNode(SAMPLE.membercount)

    if (kind === "join") {
      const pill = document.createElement("span")
      pill.className = "rounded bg-brand-100 px-1 font-medium text-accent-soft-fg"
      pill.textContent = "@" + SAMPLE.user
      return pill
    }

    return document.createTextNode("@" + SAMPLE.user)
  }
}
