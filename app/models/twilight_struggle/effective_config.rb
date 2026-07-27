# frozen_string_literal: true

module TwilightStruggle
  class EffectiveConfig
    def initialize(tournament, server_configuration)
      @tournament = tournament
      @server_configuration = server_configuration
    end

    def channel_id
      first_present(:discord_channel_id)
    end

    def template_win
      first_present(:template_win) || I18n.t("twilight_struggle.default_template.win")
    end

    def template_tie
      first_present(:template_tie) || I18n.t("twilight_struggle.default_template.tie")
    end

    def template_video
      first_present(:template_video) || I18n.t("twilight_struggle.default_template.video")
    end

    def ping_players?
      chain.find { |destination| !destination.ping_players.nil? }&.ping_players || false
    end

    def inherited_from
      chain.first&.tournament
    end

    private

    def first_present(attribute)
      chain.filter_map { |destination| destination.public_send(attribute).presence }.first
    end

    def chain
      @chain ||= build_chain
    end

    def build_chain
      return [] if @tournament.nil?

      lineage = @tournament.chain
      by_tournament = Destination
        .active
        .where(tournament: lineage, server_configuration: @server_configuration)
        .index_by(&:tournament_id)
      lineage.filter_map { |tournament| by_tournament[tournament.id] }
    end
  end
end
