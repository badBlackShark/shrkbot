import { Controller } from "@hotwired/stimulus"

const GAMES = {
  win: {
    tournament: "OTSL 2026 - Season 8",
    code: "G372",
    usa: { name: "Michał Bąk", flag: "🇵🇱", handle: "michal" },
    ussr: { name: "Lucas Sosa", flag: "🇦🇷" },
    winner: "usa",
    turn: "Turn 7",
    method: "VP Track (+20)",
    videos: "",
  },
  tie: {
    tournament: "RATS Cup 2026",
    code: "C204",
    usa: { name: "Marc Naudi", flag: "🇦🇩", handle: "marc" },
    ussr: { name: "Ji-woo Han", flag: "🇰🇷" },
    winner: null,
    turn: "Turn 10",
    method: "Wargames",
    videos: "",
  },
  video: {
    tournament: "OTSL 2026 - Season 8",
    code: "S378",
    usa: { name: "Tomasz Borowski", flag: "🇵🇱", handle: "tomasz" },
    ussr: { name: "Astrid Lindqvist", flag: "🇸🇪" },
    winner: null,
    turn: "Turn 4",
    method: "DEFCON",
    videos: "https://youtu.be/videolink",
  },
}

const SIDES = { usa: "USA", ussr: "USSR" }
const TOKEN = /\{(\w+)\}/g

export default class extends Controller {
  static targets = [
    "winTemplate", "tieTemplate", "videoTemplate",
    "winOutput", "tieOutput", "videoOutput",
    "ping",
  ]

  connect() {
    this.render()
  }

  render() {
    for (const kind of Object.keys(GAMES)) {
      this.paint(this[`${kind}TemplateTarget`], this[`${kind}OutputTarget`], GAMES[kind])
    }
  }

  reset({ params: { kind } }) {
    const input = this[`${kind}TemplateTarget`]
    input.value = input.placeholder
    input.dispatchEvent(new Event("input", { bubbles: true }))
  }

  paint(input, output, game) {
    const template = input.value.trim() || input.placeholder
    output.replaceChildren()

    if (!template) {
      output.append(this.hint(output.dataset.emptyHint))
      return
    }

    for (const node of this.nodes(template, this.tokens(game))) output.append(node)
  }

  nodes(template, tokens) {
    const out = []
    let last = 0
    let match

    TOKEN.lastIndex = 0
    while ((match = TOKEN.exec(template))) {
      if (match.index > last) out.push(this.text(template.slice(last, match.index)))
      out.push(...this.tokenNodes(match[0], tokens[match[1]]))
      last = TOKEN.lastIndex
    }
    if (last < template.length) out.push(this.text(template.slice(last)))

    return out
  }

  tokenNodes(literal, value) {
    if (value === undefined) return [this.text(literal)]
    if (typeof value === "string") return [this.text(value)]

    return [this.text(`${value.text} (`), this.pill(`@${value.handle}`), this.text(")")]
  }

  text(value) {
    return document.createTextNode(value)
  }

  pill(value) {
    const span = document.createElement("span")
    span.className = "discord-mention"
    span.textContent = value
    return span
  }

  hint(value) {
    const span = document.createElement("span")
    span.className = "discord-empty-hint"
    span.textContent = value
    return span
  }

  tokens(game) {
    const winner = game.winner ? game[game.winner] : null
    const loser = game.winner ? game[game.winner === "usa" ? "ussr" : "usa"] : null

    return {
      tournament_name: game.tournament,
      game_id: game.code,
      turn: game.turn,
      winning_method: game.method,
      winning_side: game.winner ? SIDES[game.winner] : "",
      losing_side: game.winner ? SIDES[game.winner === "usa" ? "ussr" : "usa"] : "",
      winning_player: this.player(winner),
      losing_player: this.player(loser),
      usa_player: this.player(game.usa),
      ussr_player: this.player(game.ussr),
      winning_name: this.name(winner),
      losing_name: this.name(loser),
      usa_name: this.name(game.usa),
      ussr_name: this.name(game.ussr),
      winning_flag: winner ? winner.flag : "",
      losing_flag: loser ? loser.flag : "",
      usa_flag: game.usa.flag,
      ussr_flag: game.ussr.flag,
      videos: game.videos,
    }
  }

  player(person) {
    return this.tagged(person, [person?.name, person?.flag])
  }

  name(person) {
    return this.tagged(person, [person?.name])
  }

  tagged(person, parts) {
    const text = parts.filter(Boolean).join(" ")
    if (!text) return ""
    if (!this.tags || !person.handle) return text

    return { text, handle: person.handle }
  }

  get tags() {
    return this.hasPingTarget && this.pingTarget.value === "1"
  }
}
