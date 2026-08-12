import { Controller } from "@hotwired/stimulus"
import { text, pill, hint, nodes } from "lib/token_preview"

const GAMES = {
  win: {
    tournament: "OTSL 2026 - Season 8",
    code: "G372",
    usa: { name: "Michał Bąk", flag: "🇵🇱", handle: "michal", rating: { before: 1502, after: 1522 } },
    ussr: { name: "Lucas Sosa", flag: "🇦🇷", rating: { before: 1498, after: 1478 } },
    winner: "usa",
    turn: "Turn 7",
    method: "VP Track (+20)",
    videos: "",
  },
  tie: {
    tournament: "RATS Cup 2026",
    code: "C204",
    usa: { name: "Marc Naudi", flag: "🇦🇩", handle: "marc", rating: { before: 1503, after: 1506 } },
    ussr: { name: "Ji-woo Han", flag: "🇰🇷", rating: { before: 1497, after: 1494 } },
    winner: null,
    turn: "Turn 10",
    method: "Wargames",
    videos: "",
  },
  video: {
    tournament: "OTSL 2026 - Season 8",
    code: "S378",
    usa: { name: "Tomasz Borowski", flag: "🇵🇱", handle: "tomasz", rating: { before: 1450, after: 1465 } },
    ussr: { name: "Astrid Lindqvist", flag: "🇸🇪", rating: { before: 1550, after: 1535 } },
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
      output.append(hint(output.dataset.emptyHint))
      return
    }

    const tokens = this.tokens(game)
    for (const node of nodes(template, TOKEN, (match) => this.tokenNodes(match[0], tokens[match[1]]))) {
      output.append(node)
    }
  }

  tokenNodes(literal, value) {
    if (value === undefined) return [text(literal)]
    if (typeof value === "string") return [text(value)]

    return [text(`${value.text} (`), pill(`@${value.handle}`), text(")")]
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
      usa_rating_before: this.ratingText(game.usa, "before"),
      usa_rating_after: this.ratingText(game.usa, "after"),
      usa_rating_change: this.ratingChange(game.usa),
      ussr_rating_before: this.ratingText(game.ussr, "before"),
      ussr_rating_after: this.ratingText(game.ussr, "after"),
      ussr_rating_change: this.ratingChange(game.ussr),
      winning_rating_before: this.ratingText(winner, "before"),
      winning_rating_after: this.ratingText(winner, "after"),
      winning_rating_change: this.ratingChange(winner),
      losing_rating_before: this.ratingText(loser, "before"),
      losing_rating_after: this.ratingText(loser, "after"),
      losing_rating_change: this.ratingChange(loser),
    }
  }

  player(person) {
    return this.tagged(person, [person?.name, person?.flag])
  }

  name(person) {
    return this.tagged(person, [person?.name])
  }

  ratingText(person, field) {
    const value = person?.rating?.[field]
    return value == null ? "" : String(value)
  }

  ratingChange(person) {
    const before = person?.rating?.before
    const after = person?.rating?.after
    if (before == null || after == null) return ""

    const diff = Math.round((after - before) * 100) / 100

    return `${diff >= 0 ? "+" : ""}${diff}`
  }

  tagged(person, parts) {
    const label = parts.filter(Boolean).join(" ")
    if (!label) return ""
    if (!this.tags || !person.handle) return label

    return { text: label, handle: person.handle }
  }

  get tags() {
    return this.hasPingTarget && this.pingTarget.value === "1"
  }
}
