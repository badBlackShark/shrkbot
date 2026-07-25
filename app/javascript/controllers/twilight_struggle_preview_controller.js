import { Controller } from "@hotwired/stimulus"

const GAMES = {
  win: {
    tournament: "OTSL 2026 - Season 8",
    code: "G372",
    usa: { name: "M B", flag: "🇵🇱", id: "1" },
    ussr: { name: "L S", flag: "🇦🇷", id: "2" },
    winner: "usa",
    turn: "Turn 7",
    method: "VP Track (+20)",
    videos: "",
  },
  tie: {
    tournament: "RATS Cup 2026",
    code: "C204",
    usa: { name: "M N", flag: "🇦🇩", id: "1" },
    ussr: { name: "D C", flag: "🇰🇷", id: "2" },
    winner: null,
    turn: "Turn 10",
    method: "Wargames",
    videos: "",
  },
  video: {
    tournament: "OTSL 2026 - Season 8",
    code: "S378",
    usa: { name: "T B", flag: "🇵🇱", id: "1" },
    ussr: { name: "A S", flag: "🇸🇪", id: "2" },
    winner: null,
    turn: "Turn 4",
    method: "DEFCON",
    videos: "https://youtu.be/videolink",
  },
}

const SIDES = { usa: "USA", ussr: "USSR" }

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

  paint(input, output, game) {
    const template = input.value.trim() || input.placeholder

    if (!template) {
      output.textContent = output.dataset.emptyHint
      output.classList.add("discord-empty-hint")
      return
    }

    output.classList.remove("discord-empty-hint")
    output.textContent = this.fill(template, this.tokens(game))
  }

  fill(template, tokens) {
    return template.replace(/\{(\w+)\}/g, (match, name) => (name in tokens ? tokens[name] : match))
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
    if (!person) return ""

    return [this.name(person), person.flag].filter(Boolean).join(" ")
  }

  name(person) {
    if (!person) return ""

    return this.pings ? `@${person.name}` : person.name
  }

  get pings() {
    return this.hasPingTarget && this.pingTarget.value === "1"
  }
}
