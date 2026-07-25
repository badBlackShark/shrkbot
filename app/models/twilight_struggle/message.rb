# frozen_string_literal: true

module TwilightStruggle
  class Message
    SIDE_LABELS = {usa: "USA", ussr: "USSR"}.freeze
    FINAL_SCORING_TURN = 11

    def initialize(report:, template:, tournament_name:, ping_players: false)
      @report = report
      @template = template
      @tournament_name = tournament_name
      @ping_players = ping_players
    end

    def content
      TemplateText.render(@template, tokens)
    end

    private

    def tokens
      {
        tournament_name: @tournament_name,
        game_id: @report.game_code,
        turn:,
        winning_method: @report.winning_method,
        winning_player: render_player(@report.winner),
        losing_player: render_player(@report.loser),
        winning_side: side_label(@report.winner_side),
        losing_side: side_label(@report.loser_side),
        usa_player: render_player(@report.usa),
        ussr_player: render_player(@report.ussr),
        usa_name: render_name(@report.usa),
        ussr_name: render_name(@report.ussr),
        winning_name: render_name(@report.winner),
        losing_name: render_name(@report.loser),
        usa_flag: flag_of(@report.usa),
        ussr_flag: flag_of(@report.ussr),
        winning_flag: flag_of(@report.winner),
        losing_flag: flag_of(@report.loser),
        videos: @report.video_urls.join(" ")
      }
    end

    def render_player(player)
      return "" if player.nil?

      [player.name, flag_of(player), mention_of(player)].compact_blank.join(" ")
    end

    def render_name(player)
      return "" if player.nil?

      [player.name, mention_of(player)].compact_blank.join(" ")
    end

    def mention_of(player)
      return "" unless @ping_players && player.discord_id.present?

      "(<@#{player.discord_id}>)"
    end

    def flag_of(player)
      player&.flag.to_s
    end

    def side_label(side)
      side ? SIDE_LABELS.fetch(side) : ""
    end

    def turn
      return "" if @report.winning_turn.nil?
      return "Final Scoring" if @report.winning_turn == FINAL_SCORING_TURN

      "Turn #{@report.winning_turn}"
    end
  end
end
