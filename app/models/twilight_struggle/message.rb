# frozen_string_literal: true

module TwilightStruggle
  class Message
    SIDE_LABELS = {usa: "USA", ussr: "USSR"}.freeze
    FINAL_SCORING_TURN = 11
    MAX_VIDEO_BUTTONS = 5

    def initialize(report:, template:, tournament_name:, ping_players: false)
      @report = report
      @template = template
      @tournament_name = tournament_name
      @ping_players = ping_players
    end

    def rendered
      Bot::Discord::Components.container([Bot::Discord::Components.text(body)], buttons: video_buttons)
    end

    def mention_ids
      return [] unless @ping_players

      [@report.usa.discord_id, @report.ussr.discord_id].compact
    end

    private

    def body
      TemplateText.render(@template, tokens)
    end

    def tokens
      {
        usa: render_player(@report.usa),
        ussr: render_player(@report.ussr),
        usa_flag: flag_of(@report.usa),
        ussr_flag: flag_of(@report.ussr),
        winner: render_player(@report.winner),
        loser: render_player(@report.loser),
        winner_flag: flag_of(@report.winner),
        loser_flag: flag_of(@report.loser),
        result:,
        turn:,
        method: @report.winning_method,
        game_code: @report.game_code,
        tournament: @tournament_name,
        date: @report.game_date
      }
    end

    def render_player(player)
      return "" if player.nil?

      @ping_players ? player.to_ping : player.to_s
    end

    def flag_of(player)
      player&.flag.to_s
    end

    def result
      @report.tie? ? tie_result : decided_result
    end

    def decided_result
      "#{side_fragment(@report.winner, @report.winner_side)} beat #{side_fragment(@report.loser, @report.loser_side)}"
    end

    def tie_result
      "#{side_fragment(@report.usa, :usa)} and #{side_fragment(@report.ussr, :ussr)} drew"
    end

    def side_fragment(player, side)
      [flag_of(player), "**#{render_player(player)}**", "(#{SIDE_LABELS.fetch(side)})"].compact_blank.join(" ")
    end

    def turn
      return "" if @report.winning_turn.nil?
      return "Final Scoring" if @report.winning_turn == FINAL_SCORING_TURN

      "Turn #{@report.winning_turn}"
    end

    def video_buttons
      urls = capped_video_urls
      urls.each_with_index.map { |url, index| Bot::Discord::Components.link_button(url:, label: video_label(index, urls.size)) }
    end

    def capped_video_urls
      @report.video_urls.first(MAX_VIDEO_BUTTONS)
    end

    def video_label(index, total)
      (total == 1) ? "Watch" : "Watch #{index + 1}"
    end
  end
end
